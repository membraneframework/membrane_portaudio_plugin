#include "pa_helper.h"
#define MEMBRANE_LOG_TAG log_tag
#include <membrane/log.h>

char *init_pa(UnifexEnv *env, char *log_tag, StreamDirection direction,
              PaStream **stream, void *state, PaSampleFormat sample_format,
              double *sample_rate, int *channels, char *latency_str, int *latency_ms,
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
  
  switch(direction) {
    case STREAM_DIRECTION_IN:
      if(*channels == 0) {
        *channels = device_info->maxInputChannels;
      } else if (*channels > device_info->maxInputChannels) {
        return "Device doesn't support that many input channels";
      }
      break;

    case STREAM_DIRECTION_OUT:
      if (*channels > device_info->maxOutputChannels) {
        return "Device doesn't support that many output channels";
      } else if (*channels == 0) {
        return "Channel count must be configured for output mode";
      }
      break;
  }

  if(*sample_rate <= 0.0) {
    switch(direction) {
      case STREAM_DIRECTION_IN:
        *sample_rate = device_info->defaultSampleRate;
        break;
        
      case STREAM_DIRECTION_OUT:
       return "Invalid sample rate value";
    }
  }


  PaStreamParameters stream_params = {.device = endpoint_id,
                                      .channelCount = *channels,
                                      .sampleFormat = sample_format,
                                      .suggestedLatency = latency,
                                      .hostApiSpecificStreamInfo = NULL};

  PaStreamParameters *input_stream_params_ptr = NULL;
  PaStreamParameters *output_stream_params_ptr = NULL;
  if (direction == STREAM_DIRECTION_OUT)
    output_stream_params_ptr = &stream_params;
  else
    input_stream_params_ptr = &stream_params;

  pa_error =
      Pa_OpenStream(stream, input_stream_params_ptr, output_stream_params_ptr,
                    *sample_rate, pa_buffer_size, paNoFlag, callback,
                    state // passed to the callback
      );

  if (pa_error != paNoError) {
    MEMBRANE_WARN(env, "Pa_OpenStream: error = %d (%s)", pa_error,
                  Pa_GetErrorText(pa_error));
    ret_error = "pa_open_stream";
    goto error;
  }

  const PaStreamInfo *stream_info = Pa_GetStreamInfo(*stream);
  PaTime latency_sec;
  if (direction == STREAM_DIRECTION_OUT) {
    latency_sec = stream_info->outputLatency;
  } else {
    latency_sec = stream_info->inputLatency;
  }

  *latency_ms = (int)(latency_sec * 1000);

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

PaSampleFormat string_to_PaSampleFormat(char* format) {
  if(strcmp(format, "f32le") == 0) {
    return paFloat32;
  } else if (strcmp(format, "s32le") == 0) {
    return paInt32;
  } else if (strcmp(format, "s24le") == 0) {
    return paInt24;
  } else if (strcmp(format, "s16le") == 0) {
    return paInt16;
  } else if (strcmp(format, "s8") == 0) {
    return paInt8;
  } else if (strcmp(format, "u8") == 0) {
    return paUInt8;
  }
  
  return UNSUPPORTED_SAMPLE_FORMAT;
}

int sample_size(PaSampleFormat sample_format) {
  switch (sample_format) {
    case paFloat32:
    case paInt32:
      return 4;

    case paInt24:
      return 3;

    case paInt16:
      return 2;

    case paInt8:
    case paUInt8:
      return 1;
      
    default:
      return 0;
  }
}
