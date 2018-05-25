#pragma once

#include <stdio.h>
#include <string.h>
#include <erl_nif.h>
#include <portaudio.h>
#include <membrane/membrane.h>
#include <membrane_ringbuffer/ringbuffer.h>

#include "pa_helper.h"

typedef struct _SinkHandle SinkHandle;

struct _SinkHandle
{
  char is_zombie;
  PaStream* stream;
  MembraneRingBuffer* ringbuffer;
  ErlNifPid demand_handler; // Where to send demands
};

ErlNifResourceType *RES_SINK_HANDLE_TYPE;

void res_sink_handle_destructor(ErlNifEnv *env, void *value);
ERL_NIF_TERM export_sink_create(ErlNifEnv* env, int _argc, const ERL_NIF_TERM argv[]);
ERL_NIF_TERM export_write(ErlNifEnv* env, int _argc, const ERL_NIF_TERM argv[]);
ERL_NIF_TERM export_sink_destroy(ErlNifEnv* env, int _argc, const ERL_NIF_TERM argv[]);
