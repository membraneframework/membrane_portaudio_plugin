#pragma once

#include <stdio.h>
#include <string.h>
#include <erl_nif.h>
#include <portaudio.h>
#include <membrane/membrane.h>

/**
This mutex is used for preventing parallel calls to non thread-safe PortAudio
functions (such as Pa_Initialize, Pa_OpenStream, Pa_StartStream, Pa_StopStream,
Pa_Terminate).
*/
ErlNifMutex* pa_mutex;

char* init_pa(
  ErlNifEnv* env, char* log_tag, char direction, PaStream** stream, void* handle,
  PaSampleFormat sample_format, int sample_rate, int channels, char* latency_str,
  int pa_buffer_size, PaDeviceIndex endpoint_id, PaStreamCallback* callback
);

char* destroy_pa(ErlNifEnv* env, char* log_tag, PaStream* stream);
