#pragma once

#include <membrane/membrane.h>
#include <membrane_ringbuffer/ringbuffer.h>
#include <portaudio.h>
#include <stdio.h>
#include <string.h>

#include "pa_helper.h"

typedef struct _SinkState {
  int is_content_destroyed;
  PaStream *stream;
  MembraneRingBuffer *ringbuffer;
  UnifexPid demand_handler; // Where to send demands
  int demand;
} SinkState;

typedef SinkState UnifexNifState;

#include "_generated/sink.h"
