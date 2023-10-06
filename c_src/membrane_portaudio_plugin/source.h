#pragma once

#include <membrane/membrane.h>
#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wall"
#pragma GCC diagnostic ignored "-Wextra" 
#include <portaudio.h>
#pragma GCC diagnostic pop
#include <stdio.h>
#include <string.h>

#include "pa_helper.h"

typedef struct _SourceState {
  int is_content_destroyed;
  int channels;
  int frame_size;
  PaStream *stream;
  UnifexPid destination; // Where capture thread will send messages
} SourceState;

#include "_generated/source.h"
