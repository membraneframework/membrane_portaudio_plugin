/**
 * Membrane Element: PortAudio - Erlang native interface for portaudio-based sink
 *
 * All Rights Reserved, (c) 2016 Marcin Lewandowski
 */


#ifndef __SINK_H__
#define __SINK_H__

#include <stdio.h>
#include <string.h>
#include <erl_nif.h>
#include <portaudio.h>
#include <membrane/membrane.h>

#include "pa_ringbuffer.h"


typedef struct _SinkHandle SinkHandle;

struct _SinkHandle
{
  PaStream         *stream;           // Port Audio stream
  PaUtilRingBuffer *ringbuffer;       // Ring buffer that will keep data before it is written to the sound card
  void             *ringbuffer_data;  // Ring buffer's memory
};

#endif
