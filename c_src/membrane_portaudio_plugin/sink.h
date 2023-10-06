#pragma once

#include <membrane/membrane.h>
#include <membrane_ringbuffer/ringbuffer.h>
#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wall"
#pragma GCC diagnostic ignored "-Wextra" 
#include <portaudio.h>
#pragma GCC diagnostic pop
#include <stdio.h>
#include <string.h>

#include "pa_helper.h"

typedef struct _SinkState {
  int is_content_destroyed;
  PaStream *stream;
  MembraneRingBuffer *ringbuffer;
  UnifexPid demand_handler; // Where to send demands
  UnifexPid membrane_clock;
  int demand;
  int ticks;
  int sample_rate;
  int frame_size;
} SinkState;

#include "_generated/sink.h"
