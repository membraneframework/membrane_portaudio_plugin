#include "source.h"
#define MEMBRANE_LOG_TAG "Membrane.Element.PortAudio.Source.Native"
#include <membrane/log.h>

#define UNUSED(x) (void)(x)

void res_source_handle_destructor(ErlNifEnv *env, void *value) {
  SourceHandle *handle = (SourceHandle *) value;
  if(handle->is_zombie) return;

  MEMBRANE_DEBUG(env, "Destroying SourceHandle %p", value);

  destroy_pa(env, MEMBRANE_LOG_TAG, handle->stream);
}


static int callback(const void *input_buffer, void *_output_buffer, unsigned long frames, const PaStreamCallbackTimeInfo* _time_info, PaStreamCallbackFlags _flags, void *user_data) {
  UNUSED(_output_buffer);
  UNUSED(_time_info);
  UNUSED(_flags);
  ErlNifEnv *msg_env;
  ERL_NIF_TERM packet_term;
  size_t packet_size_in_bytes = frames * 2 * 2; // we use 16 bit, 2 channels
  SourceHandle *handle = (SourceHandle *) user_data;


  // Send packet upstream
  msg_env = enif_alloc_env();

  unsigned char *packet_data_binary = enif_make_new_binary(msg_env, packet_size_in_bytes, &packet_term);
  memcpy(packet_data_binary, input_buffer, packet_size_in_bytes);

  ERL_NIF_TERM tuple[2] = {
    enif_make_atom(msg_env, "membrane_element_portaudio_source_packet"),
    packet_term
  };
  ERL_NIF_TERM msg = enif_make_tuple_from_array(msg_env, tuple, 2);


  if(!enif_send(NULL, &handle->destination, msg_env, msg)) {
    MEMBRANE_THREADED_WARN("Capture: packet send failed");
  }

  enif_free_env(msg_env);

  return paContinue;
}


ERL_NIF_TERM export_source_create(ErlNifEnv* env, int _argc, const ERL_NIF_TERM argv[]) {
  UNUSED(_argc);

  MEMBRANE_UTIL_PARSE_PID_ARG(0, destination);
  MEMBRANE_UTIL_PARSE_INT_ARG(1, endpoint_id);
  MEMBRANE_UTIL_PARSE_INT_ARG(2, pa_buffer_size);
  MEMBRANE_UTIL_PARSE_ATOM_ARG(3, latency_str, 255);

  MEMBRANE_DEBUG(env, "initializing");

  SourceHandle* handle = enif_alloc_resource(RES_SOURCE_HANDLE_TYPE, sizeof(SourceHandle));
  handle->is_zombie = 0;
  handle->destination = destination;
  handle->stream = NULL;

  char* error = init_pa(
    env,
    MEMBRANE_LOG_TAG,
    0, //direction
    &(handle->stream),
    handle,
    paInt16, //sample format #FIXME hardcoded0
    48000, //sample rate #FIXME hardcoded
    2, //channels #FIXME hardcoded
    latency_str,
    pa_buffer_size,
    endpoint_id,
    callback
  );

  if(error) {
    enif_release_resource(handle);
    return membrane_util_make_error_internal(env, error);
  }

  ERL_NIF_TERM handle_term = enif_make_resource(env, handle);
  enif_release_resource(handle);

  return membrane_util_make_ok_tuple(env, handle_term);
}


ERL_NIF_TERM export_source_destroy(ErlNifEnv* env, int _argc, const ERL_NIF_TERM argv[]) {
  UNUSED(_argc);

  MEMBRANE_UTIL_PARSE_RESOURCE_ARG(0, handle, SourceHandle, RES_SOURCE_HANDLE_TYPE);

  if(!handle->is_zombie) {

    destroy_pa(env, MEMBRANE_LOG_TAG, handle->stream);
    handle->stream = NULL;

    handle->is_zombie = 1;
  }

  return membrane_util_make_ok(env);
}
