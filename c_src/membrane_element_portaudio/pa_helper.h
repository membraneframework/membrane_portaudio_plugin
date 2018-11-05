#pragma once

#include <membrane/membrane.h>
#include <portaudio.h>
#include <stdio.h>
#include <string.h>
#include <unifex/unifex.h>

char *init_pa(UnifexEnv *env, char *log_tag, char direction, PaStream **stream,
              void *state, PaSampleFormat sample_format, int sample_rate,
              int channels, char *latency_str, int pa_buffer_size,
              PaDeviceIndex endpoint_id, PaStreamCallback *callback);

char *destroy_pa(UnifexEnv *env, char *log_tag, PaStream *stream);
