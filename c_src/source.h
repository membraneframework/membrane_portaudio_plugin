/**
 * Membrane Element: PortAudio - Erlang native interface for portaudio-based source
 *
 * All Rights Reserved, (c) 2016 Marcin Lewandowski
 */


#ifndef __SOURCE_H__
#define __SOURCE_H__

#include <stdio.h>
#include <string.h>
#include <erl_nif.h>
#include <portaudio.h>
#include <membrane/membrane.h>

typedef struct _SourceHandle SourceHandle;

struct _SourceHandle
{
  PaStream   *stream;          // Port Audio stream
  ErlNifPid  *destination;     // Where capture thread will send messages
};

#endif
