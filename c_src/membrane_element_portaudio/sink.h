/**
 * Membrane Element: PortAudio - Erlang native interface for portaudio-based sink
 *
 * All Rights Reserved, (c) 2016 Marcin Lewandowski
 */


#pragma once

#include <stdio.h>
#include <string.h>
#include <erl_nif.h>
#include <portaudio.h>
#include <membrane/membrane.h>
#define MEMBRANE_LOG_TAG "Membrane.Element.PortAudio.Sink.Native"
#include <membrane/log.h>
#include <membrane_ringbuffer/ringbuffer.h>

typedef struct _SinkHandle SinkHandle;

struct _SinkHandle
{
  PaStream* stream;
  MembraneRingBuffer* ringbuffer;
  ErlNifPid demand_handler; // Where to send demands
};
