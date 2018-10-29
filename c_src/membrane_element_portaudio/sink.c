#include "sink.h"
#define MEMBRANE_LOG_TAG UNIFEX_MODULE
#include <membrane/log.h>

#define FRAME_SIZE 4 // FIXME hardcoded format, stereo frame, 16bit

void handle_destroy_state(UnifexEnv *env, SinkState *state) {
  if (state->is_content_destroyed)
    return;
  SinkState *temp_state = unifex_alloc_state(env);
  memcpy(temp_state, state, sizeof(SinkState));

  UnifexPid exec_pid;
  if (!unifex_get_pid_by_name(
          env, "Elixir.Membrane.Element.PortAudio.SyncExecutor", &exec_pid) ||
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

  size_t elements_available =
      membrane_ringbuffer_get_read_available(state->ringbuffer);
  if (elements_available >= frames_per_buffer) {
    size_t elements_read = membrane_ringbuffer_read(
        state->ringbuffer, output_buffer, frames_per_buffer);
    if (state->demand + elements_read > state->ringbuffer->max_elements / 2) {
      if (!send_demand(env, state->demand_handler, UNIFEX_SEND_THREADED,
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
  unifex_clear_env(env);
  return paContinue;
}

UNIFEX_TERM create(UnifexEnv *env, UnifexPid demand_handler, int endpoint_id,
                   int ringbuffer_size, int pa_buffer_size, char *latency) {
  MEMBRANE_DEBUG(env, "initializing");

  MembraneRingBuffer *ringbuffer =
      membrane_ringbuffer_new(ringbuffer_size, FRAME_SIZE);
  if (!ringbuffer) {
    MEMBRANE_WARN(env, "Error initializing ringbuffer");
    return create_result_error(env, "ringbuffer_init");
  }

  send_demand(env, demand_handler, UNIFEX_NO_FLAGS,
              ringbuffer_size * FRAME_SIZE);

  SinkState *state = unifex_alloc_state(env);
  state->is_content_destroyed = 0;
  state->ringbuffer = ringbuffer;
  state->demand_handler = demand_handler;
  state->stream = NULL;
  state->demand = 0;

  char *error = init_pa(env, MEMBRANE_LOG_TAG,
                        1, // direction
                        &(state->stream), state,
                        paInt16, // sample format #FIXME hardcoded0
                        48000,   // sample rate #FIXME hardcoded
                        2,       // channels #FIXME hardcoded
                        latency, pa_buffer_size, endpoint_id, callback);

  if (error) {
    unifex_release_state(env, state);
    return create_result_error(env, error);
  }

  UNIFEX_TERM res = create_result_ok(env, state);
  unifex_release_state(env, state);
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
