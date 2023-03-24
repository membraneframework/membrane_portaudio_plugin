#include "source.h"
#define MEMBRANE_LOG_TAG "Membrane.PortAudio.Sink"
#include <membrane/log.h>

#define SAMPLE_SIZE 2 // TODO hardcoded format, 16bit

void handle_destroy_state(UnifexEnv *env, SourceState *state) {
  if (state->is_content_destroyed)
    return;
  SourceState *temp_state = unifex_alloc_state(env);
  memcpy(temp_state, state, sizeof(SourceState));

  UnifexPid exec_pid;
  if (!unifex_get_pid_by_name(env, "Elixir.Membrane.PortAudio.SyncExecutor", 0,
                              &exec_pid) ||
      !send_destroy(env, exec_pid, 0, temp_state)) {
    MEMBRANE_WARN(env, "Failed to destroy state");
  }
}

static int callback(const void *input_buffer, void *_output_buffer,
                    unsigned long frames,
                    const PaStreamCallbackTimeInfo *_time_info,
                    PaStreamCallbackFlags _flags, void *user_data) {
  UNIFEX_UNUSED(_output_buffer);
  UNIFEX_UNUSED(_time_info);
  UNIFEX_UNUSED(_flags);

  SourceState *state = (SourceState *)user_data;
  UnifexEnv *env = unifex_alloc_env(NULL);

  UnifexPayload payload;
  unifex_payload_alloc(env, UNIFEX_PAYLOAD_BINARY, frames * state->channels * SAMPLE_SIZE, &payload);
  memcpy(payload.data, input_buffer, payload.size);
  if (!send_portaudio_payload(env, state->destination, UNIFEX_SEND_THREADED,
                              &payload)) {
    MEMBRANE_THREADED_WARN(env, "Payload send failed");
  }
  unifex_payload_release(&payload);

  unifex_free_env(env);

  return paContinue;
}

UNIFEX_TERM create(UnifexEnv *env, UnifexPid destination, int endpoint_id,
                   int pa_buffer_size, char *latency, int max_channels) {
  MEMBRANE_DEBUG(env, "Initializing");

  SourceState *state = unifex_alloc_state(env);
  state->is_content_destroyed = 0;
  state->destination = destination;
  state->stream = NULL;
  
  double sample_rate = -1.0;

  int _latency_ms;
  char *error = init_pa(
      env, MEMBRANE_LOG_TAG, STREAM_DIRECTION_IN, &(state->stream), state,
      paInt16, // sample format
      &sample_rate, // device's default sample rate will be selected
      &max_channels,
      latency, &_latency_ms, pa_buffer_size, endpoint_id, callback);
  
  state->channels = max_channels;

  UNIFEX_TERM res =
      error ? create_result_error(env, error) : create_result_ok(env, state, max_channels, floor(sample_rate));
  unifex_release_state(env, state);
  return res;
}

UNIFEX_TERM destroy(UnifexEnv *env, SourceState *state) {
  destroy_pa(env, MEMBRANE_LOG_TAG, state->stream);
  state->stream = NULL;
  state->is_content_destroyed = 1;

  return destroy_result(env);
}
