#pragma once

#include <stdio.h>
#include <string.h>
#include <erl_nif.h>
#include <portaudio.h>
#include <membrane/membrane.h>

#include "pa_helper.h"

typedef struct _SourceHandle SourceHandle;

struct _SourceHandle
{
  int is_content_destroyed;
  PaStream *stream;
  ErlNifPid destination; // Where capture thread will send messages
};

ErlNifResourceType *RES_SOURCE_HANDLE_TYPE;

void res_source_handle_destructor(ErlNifEnv *env, void *value);
ERL_NIF_TERM export_source_create(ErlNifEnv* env, int _argc, const ERL_NIF_TERM argv[]);
ERL_NIF_TERM export_source_destroy(ErlNifEnv* env, int _argc, const ERL_NIF_TERM argv[]);
