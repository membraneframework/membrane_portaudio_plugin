/**
 * Membrane Element: PortAudio - Erlang native interface for portaudio-based source
 *
 * All Rights Reserved, (c) 2016 Marcin Lewandowski
 */


#include "source.h"

#define MEMBRANE_LOG_TAG  "Membrane.Element.PortAudio.SourceNative"


ErlNifResourceType *RES_SOURCE_HANDLE_TYPE;


static void res_source_handle_destructor(ErlNifEnv *env, void *value) {
  PaError error;
  SourceHandle *source_handle = (SourceHandle *) value;

  MEMBRANE_DEBUG("Destroying SourceHandle %p", value);

  if(Pa_IsStreamStopped(source_handle->stream) == 0) {
    error = Pa_StopStream(source_handle->stream);
    if(error != paNoError) {
      MEMBRANE_DEBUG("Pa_StopStream: error = %d", error);
    }
  }

  error = Pa_CloseStream(source_handle->stream);
  if(error != paNoError) {
    MEMBRANE_DEBUG("Pa_CloseStream: error = %d", error);
  }

  error = Pa_Terminate();
  if(error != paNoError) {
    MEMBRANE_DEBUG("Pa_Terminate: error = %d", error);
  }
}


static int load(ErlNifEnv *env, void **priv_data, ERL_NIF_TERM load_info) {
  int flags = ERL_NIF_RT_CREATE | ERL_NIF_RT_TAKEOVER;
  RES_SOURCE_HANDLE_TYPE =
    enif_open_resource_type(env, NULL, "SourceHandle", res_source_handle_destructor, flags, NULL);

  return 0;
}



static int callback(const void *input_buffer, void *output_buffer, unsigned long frames, const PaStreamCallbackTimeInfo* time_info, PaStreamCallbackFlags flags, void *user_data) {
  ErlNifEnv    *msg_env;
  ErlNifPid     destination;
  ERL_NIF_TERM  packet_term;
  size_t        packet_size_in_bytes = frames * 2 * 2; // we use 16 bit, 2 channels
  SourceHandle *source_handle = (SourceHandle *) user_data;


  // Send packet upstream
  msg_env = enif_alloc_env();

  unsigned char *packet_data_binary = enif_make_new_binary(msg_env, packet_size_in_bytes, &packet_term);
  memcpy(packet_data_binary, input_buffer, packet_size_in_bytes);

  ERL_NIF_TERM tuple[2] = {
    enif_make_atom(msg_env, "membrane_element_portaudio_source_packet"),
    packet_term
  };
  ERL_NIF_TERM msg = enif_make_tuple_from_array(msg_env, tuple, 2);


  if(!enif_send(NULL, source_handle->destination, msg_env, msg)) {
    MEMBRANE_DEBUG("Capture: packet send failed");
  }

  enif_free_env(msg_env);

  return paContinue;
}


static ERL_NIF_TERM export_start(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[])
{
  SourceHandle *source_handle;
  PaError error;


  // Get source_handle arg
  if(!enif_get_resource(env, argv[0], RES_SOURCE_HANDLE_TYPE, (void **) &source_handle)) {
    return membrane_util_make_error_args(env, "source_handle", "Passed source_handle is not valid resource");
  }


  // Start the stream
  error = Pa_StartStream(source_handle->stream);
  if(error != paNoError) {
    MEMBRANE_DEBUG("Pa_StartStream: error = %d", error);
    return membrane_util_make_error_internal(env, "pastartstream");
  }


  // Return
  return membrane_util_make_ok(env);
}


static ERL_NIF_TERM export_stop(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[])
{
  SourceHandle *source_handle;
  PaError error;


  // Get source_handle arg
  if(!enif_get_resource(env, argv[0], RES_SOURCE_HANDLE_TYPE, (void **) &source_handle)) {
    return membrane_util_make_error_args(env, "source_handle", "Passed source_handle is not valid resource");
  }


  // Stop the stream
  error = Pa_StopStream(source_handle->stream);
  if(error != paNoError) {
    MEMBRANE_DEBUG("Pa_StartStream: error = %d", error);
    return membrane_util_make_error_internal(env, "paclosestream");
  }


  // Return
  return membrane_util_make_ok(env);
}


static ERL_NIF_TERM export_create(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[])
{
  int             buffer_size;
  char            device_id[64];
  SourceHandle   *source_handle;
  PaError         error;


  // Get device ID arg
  // FIXME it is not going to be an atom
  // if(!enif_get_atom(env, argv[0], (char *) device_id, ENDPOINT_ID_LEN, ERL_NIF_LATIN1)) {
  //   return membrane_util_make_error_args(env, "device_id", "Passed device ID is not valid");
  // }


  // Get destination arg
  ErlNifPid* destination = (ErlNifPid*) enif_alloc(sizeof(ErlNifPid));
  if(!enif_get_local_pid(env, argv[1], destination)) {
    return membrane_util_make_error_args(env, "destination", "Passed destination is not valid pid");
  }


  // Get buffer size arg
  if(!enif_get_int(env, argv[2], &buffer_size)) {
    return membrane_util_make_error_args(env, "buffer_duration", "Passed buffer size is out of integer range or is not an integer");
  }




  // Initialize handle
  source_handle = (SourceHandle *) enif_alloc_resource(RES_SOURCE_HANDLE_TYPE, sizeof(SourceHandle));
  MEMBRANE_DEBUG("Creating SourceHandle %p", source_handle);

  source_handle->destination = destination;


  // Initialize PortAudio
  error = Pa_Initialize();
  if(error != paNoError) {
    MEMBRANE_DEBUG("Pa_Initialize: error = %d", error);
    return membrane_util_make_error_internal(env, "painitialize");
  }


  // Open stream for the default device
  error = Pa_OpenDefaultStream(&(source_handle->stream),
                              2,              // 2 input channels
                              0,              // no output
                              paInt16,        // 16 bit integer format FIXME hardcoded
                              48000,          // sample rate FIXME hardcoded
                              buffer_size,    // frames per buffer
                              callback,       // callback function for processing
                              source_handle); // user data passed to the callback

  if(error != paNoError) {
    MEMBRANE_DEBUG("Pa_OpenDefaultStream: error = %d", error);
    return membrane_util_make_error_internal(env, "paopendefaultstream");
  }


  // Store handle as an erlang resource
  ERL_NIF_TERM source_handle_term = enif_make_resource(env, source_handle);
  enif_release_resource(source_handle);


  // Return
  return membrane_util_make_ok_tuple(env, source_handle_term);
}


static ErlNifFunc nif_funcs[] =
{
  {"create", 3, export_create},
  {"start", 1, export_start},
  {"stop", 1, export_stop}
};


ERL_NIF_INIT(Elixir.Membrane.Element.PortAudio.SourceNative, nif_funcs, load, NULL, NULL, NULL)
