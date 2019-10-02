#include "sink.h"
#define MEMBRANE_LOG_TAG UNIFEX_MODULE
#include <membrane/log.h>

#define FRAME_SIZE 4 // TODO hardcoded format, stereo frame, 16bit
#define BUFFERS_PER_TICK 100

#define SAMPLE_RATE 48000
#define SAMPLE_RATE_PER_MS (SAMPLE_RATE / 100)
#define CHANNELS_NUM 2

void handle_destroy_state(UnifexEnv *env, SinkState *state) {
  if (state->is_content_destroyed)
    return;
  SinkState *temp_state = unifex_alloc_state(env);
  memcpy(temp_state, state, sizeof(SinkState));

  UnifexPid exec_pid;
  if (!unifex_get_pid_by_name(env,
                              "Elixir.Membrane.Element.PortAudio.SyncExecutor",
                              0, &exec_pid) ||
      !send_destroy(env, exec_pid, 0, temp_state)) {
    MEMBRANE_WARN(env, "PortAudio sink: failed to destroy state");
  }
}

static int callback(const void *_input_buffer, void *output_buffer,
                    unsigned long frames_per_buffer,
                    const PaStreamCallbackTimeInfo *_time_info,
                    PaStreamCallbackFlags _flags, void *user_data) {
  UNIFEX_UNUSED(_input_buffer);
  UNIFEX_UNUSED(_time_info);
  UNIFEX_UNUSED(_flags);

  UnifexEnv *env = unifex_alloc_env();
  SinkState *state = (SinkState *)user_data;

  if (++state->ticks % BUFFERS_PER_TICK == 0) {
    send_membrane_clock_update(env, state->membrane_clock, UNIFEX_SEND_THREADED,
                               BUFFERS_PER_TICK * frames_per_buffer,
                               SAMPLE_RATE_PER_MS);
  }

  size_t elements_available =
      membrane_ringbuffer_get_read_available(state->ringbuffer);
  if (elements_available >= frames_per_buffer) {
    size_t elements_read = membrane_ringbuffer_read(
        state->ringbuffer, output_buffer, frames_per_buffer);
    if (state->demand + elements_read > state->ringbuffer->max_elements / 2) {
      if (!send_portaudio_demand(
              env, state->demand_handler, UNIFEX_SEND_THREADED,
              (state->demand + elements_read) * FRAME_SIZE)) {
        MEMBRANE_THREADED_WARN(env, "PortAudio sink: failed to send demand");
      }
      state->demand = 0;
    } else {
      state->demand += elements_read;
    }
  } else {
    memset(output_buffer, 0, frames_per_buffer * FRAME_SIZE);
  }
  unifex_free_env(env);
  return paContinue;
}

UNIFEX_TERM create(UnifexEnv *env, UnifexPid demand_handler,
                   UnifexPid membrane_clock, int endpoint_id,
                   int ringbuffer_size, int pa_buffer_size, char *latency) {
  MEMBRANE_DEBUG(env, "initializing");

  char *error;
  SinkState *state = NULL;
  int latency_ms;
  UNIFEX_TERM res;

  MembraneRingBuffer *ringbuffer =
      membrane_ringbuffer_new(ringbuffer_size, FRAME_SIZE);
  if (!ringbuffer) {
    MEMBRANE_WARN(env, "Error initializing ringbuffer");
    error = "ringbuffer_init";
    goto error;
  }

  send_portaudio_demand(env, demand_handler, UNIFEX_NO_FLAGS,
                        ringbuffer_size * FRAME_SIZE);

  state = unifex_alloc_state(env);
  state->is_content_destroyed = 0;
  state->ringbuffer = ringbuffer;
  state->demand_handler = demand_handler;
  state->membrane_clock = membrane_clock;
  state->stream = NULL;
  state->demand = 0;
  state->ticks = 0;

  error = init_pa(env, MEMBRANE_LOG_TAG, STREAM_DIRECTION_OUT, &(state->stream),
                  state,
                  paInt16,      // sample format #TODO hardcoded
                  SAMPLE_RATE,  // sample rate #TODO hardcoded
                  CHANNELS_NUM, // channels #TODO hardcoded
                  latency, &latency_ms, pa_buffer_size, endpoint_id, callback);

  if (error) {
    goto error;
  }

error:

  res = error ? create_result_error(env, error)
              : create_result_ok(env, latency_ms, state);

  if (state) {
    unifex_release_state(env, state);
  }

  return res;
}

UNIFEX_TERM write_data(UnifexEnv *env, UnifexPayload *payload,
                       SinkState *state) {
  size_t elements_written = membrane_ringbuffer_write(
      state->ringbuffer, payload->data, payload->size / FRAME_SIZE);
  if (elements_written != payload->size / FRAME_SIZE) {
    MEMBRANE_WARN(env,
                  "Write: written only %d out of %lu bytes into ringbuffer",
                  elements_written * FRAME_SIZE, payload->size);
    return write_data_result_error_overrun(env);
  }
  return write_data_result_ok(env);
}

UNIFEX_TERM destroy(UnifexEnv *env, SinkState *state) {
  destroy_pa(env, MEMBRANE_LOG_TAG, state->stream);
  state->stream = NULL;

  if (state->ringbuffer) {
    membrane_ringbuffer_destroy(state->ringbuffer);
    state->ringbuffer = NULL;
  }

  state->is_content_destroyed = 1;

  return destroy_result(env);
}
