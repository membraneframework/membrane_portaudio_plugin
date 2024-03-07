#pragma once

#include <membrane/membrane.h>
#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wall"
#pragma GCC diagnostic ignored "-Wextra"
#include <portaudio.h>
#pragma GCC diagnostic pop
#include <stdio.h>
#include <string.h>
#include <unifex/unifex.h>

typedef enum { STREAM_DIRECTION_IN, STREAM_DIRECTION_OUT } StreamDirection;

char *init_pa(UnifexEnv *env, char *log_tag, StreamDirection direction,
              PaStream **stream, void *state, PaSampleFormat sample_format,
              double *sample_rate, int *channels, char *latency_str,
              int *latency_ms, int pa_buffer_size, PaDeviceIndex device_id,
              PaStreamCallback *callback);

char *destroy_pa(UnifexEnv *env, char *log_tag, PaStream *stream);

#define UNSUPPORTED_SAMPLE_FORMAT 0
PaSampleFormat string_to_PaSampleFormat(char *format);

int sample_size(PaSampleFormat);
