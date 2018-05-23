#include "native.h"

#define UNUSED(x) (void)(x)


static int load(ErlNifEnv *env, void **_priv_data, ERL_NIF_TERM _load_info) {
  UNUSED(_priv_data);
  UNUSED(_load_info);

  pa_mutex = enif_mutex_create("pa_mutex");

  int flags = ERL_NIF_RT_CREATE | ERL_NIF_RT_TAKEOVER;
  RES_SINK_HANDLE_TYPE =
    enif_open_resource_type(env, NULL, "SinkHandle", res_sink_handle_destructor, flags, NULL);

  RES_SOURCE_HANDLE_TYPE =
    enif_open_resource_type(env, NULL, "SourceHandle", res_source_handle_destructor, flags, NULL);

  return 0;
}

static void unload(ErlNifEnv* _env, void* _priv_data) {
  UNUSED(_priv_data);
  UNUSED(_env);

  enif_mutex_destroy(pa_mutex);
}

static ErlNifFunc nif_funcs[] = {
  {"create_sink", 5, export_sink_create, 0},
  {"write", 2, export_write, 0},
  {"destroy_sink", 1, export_sink_destroy, 0},
  {"create_source", 4, export_source_create, 0},
  {"destroy_source", 1, export_source_destroy, 0}
};


ERL_NIF_INIT(Elixir.Membrane.Element.PortAudio.Native.Nif, nif_funcs, load, NULL, NULL, unload)
