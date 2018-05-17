/**
 * Membrane Element: PortAudio - Erlang native interface for portaudio-based source
 *
 * All Rights Reserved, (c) 2016 Marcin Lewandowski
 */


#pragma once

#include <stdio.h>
#include <string.h>
#include <erl_nif.h>
#include <portaudio.h>
#include <membrane/membrane.h>
#define MEMBRANE_LOG_TAG "Membrane.Element.PortAudio.Source.Native"
#include <membrane/log.h>

#include "pa_stream.h"

typedef struct _SourceHandle SourceHandle;

struct _SourceHandle
{
  PaStream *stream;
  ErlNifPid destination; // Where capture thread will send messages
};
