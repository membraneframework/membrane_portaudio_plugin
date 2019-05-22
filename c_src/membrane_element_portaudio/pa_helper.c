#include "pa_helper.h"
#define MEMBRANE_LOG_TAG log_tag
#include <membrane/log.h>

char *init_pa(UnifexEnv *env, char *log_tag, char direction, PaStream **stream,
              void *state, PaSampleFormat sample_format, int sample_rate,
              int channels, char *latency_str, int *latency_ms,
              int pa_buffer_size, PaDeviceIndex endpoint_id,
              PaStreamCallback *callback) {
  char *ret_error = NULL;
  PaError pa_error;

  pa_error = Pa_Initialize();
  if (pa_error != paNoError) {
    MEMBRANE_WARN(env, "Pa_Initialize: error = %d (%s)", pa_error,
                  Pa_GetErrorText(pa_error));
    ret_error = "pa_init_error";
    goto error;
  }

  if (endpoint_id == paNoDevice) {
    endpoint_id =
        direction ? Pa_GetDefaultOutputDevice() : Pa_GetDefaultInputDevice();
  }

  const PaDeviceInfo *device_info = Pa_GetDeviceInfo(endpoint_id);
  if (!device_info) {
    MEMBRANE_WARN(env, "Invalid endpoint id: %d", endpoint_id);
    ret_error = "invalid_endpoint_id";
    goto error;
  }

  PaTime latency;
  if (!strcmp(latency_str, "high"))
    latency = device_info->defaultHighOutputLatency;
  else if (!strcmp(latency_str, "low"))
    latency = device_info->defaultLowOutputLatency;
  else {
    MEMBRANE_WARN(env, "Invalid latency: %s", latency_str);
    ret_error = "invalid_latency";
    goto error;
  }
  *latency_ms = (int)(latency * 1000);

  PaStreamParameters stream_params = {.device = endpoint_id,
                                      .channelCount = channels,
                                      .sampleFormat = sample_format,
                                      .suggestedLatency = latency,
                                      .hostApiSpecificStreamInfo = NULL};

  PaStreamParameters *input_stream_params_ptr = NULL;
  PaStreamParameters *output_stream_params_ptr = NULL;
  if (direction)
    output_stream_params_ptr = &stream_params;
  else
    input_stream_params_ptr = &stream_params;

  pa_error =
      Pa_OpenStream(stream, input_stream_params_ptr, output_stream_params_ptr,
                    sample_rate, pa_buffer_size,
                    0, // PaStreamFlags
                    callback,
                    state // passed to the callback
      );

  if (pa_error != paNoError) {
    MEMBRANE_WARN(env, "Pa_OpenStream: error = %d (%s)", pa_error,
                  Pa_GetErrorText(pa_error));
    ret_error = "pa_open_stream";
    goto error;
  }

  pa_error = Pa_StartStream(*stream);
  if (pa_error != paNoError) {
    MEMBRANE_WARN(env, "Pa_StartStream: error = %d (%s)", pa_error,
                  Pa_GetErrorText(pa_error));
    ret_error = "pa_start_stream";
    goto error;
  }

error:
  return ret_error;
}

char *destroy_pa(UnifexEnv *env, char *log_tag, PaStream *stream) {
  PaError pa_error;
  char *error = NULL;

  if (stream) {
    if (Pa_IsStreamStopped(stream) == 0) {
      pa_error = Pa_StopStream(stream);
      if (pa_error != paNoError) {
        MEMBRANE_WARN(env, "Pa_StopStream: error = %d (%s)", pa_error,
                      Pa_GetErrorText(pa_error));
        if (!error)
          error = "pa_stop_stream";
      }
    }

    pa_error = Pa_CloseStream(stream);
    if (pa_error != paNoError && pa_error != paNotInitialized) {
      MEMBRANE_WARN(env, "Pa_CloseStream: error = %d (%s)", pa_error,
                    Pa_GetErrorText(pa_error));
      if (!error)
        error = "pa_close_stream";
    }
  }

  pa_error = Pa_Terminate();
  if (pa_error != paNoError) {
    MEMBRANE_WARN(env, "Pa_Terminate: error = %d (%s)", pa_error,
                  Pa_GetErrorText(pa_error));
  }

  return error;
}
