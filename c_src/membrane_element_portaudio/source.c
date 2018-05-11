/**
 * Membrane Element: PortAudio - Erlang native interface for portaudio-based source
 *
 * All Rights Reserved, (c) 2016 Marcin Lewandowski
 */


#include "source.h"

#define UNUSED(x) (void)(x)

ErlNifResourceType *RES_SOURCE_HANDLE_TYPE;


static void res_source_handle_destructor(ErlNifEnv *env, void *value) {
  PaError error;
  SourceHandle *source_handle = (SourceHandle *) value;

  MEMBRANE_DEBUG(env, "Destroying SourceHandle %p", value);

  if(Pa_IsStreamStopped(source_handle->stream) == 0) {
    error = Pa_StopStream(source_handle->stream);
    if(error != paNoError) {
      MEMBRANE_WARN(env, "Pa_StopStream: error = %d (%s)", error, Pa_GetErrorText(error));
    }
  }

  error = Pa_CloseStream(source_handle->stream);
  if(error != paNoError) {
    MEMBRANE_WARN(env, "Pa_CloseStream: error = %d (%s)", error, Pa_GetErrorText(error));
  }

  error = Pa_Terminate();
  if(error != paNoError) {
    MEMBRANE_WARN(env, "Pa_Terminate: error = %d (%s)", error, Pa_GetErrorText(error));
  }
}


static int load(ErlNifEnv *env, void **_priv_data, ERL_NIF_TERM _load_info) {
  UNUSED(_priv_data);
  UNUSED(_load_info);
  int flags = ERL_NIF_RT_CREATE | ERL_NIF_RT_TAKEOVER;
  RES_SOURCE_HANDLE_TYPE =
    enif_open_resource_type(env, NULL, "SourceHandle", res_source_handle_destructor, flags, NULL);

  return 0;
}



static int callback(const void *input_buffer, void *_output_buffer, unsigned long frames, const PaStreamCallbackTimeInfo* _time_info, PaStreamCallbackFlags _flags, void *user_data) {
  UNUSED(_output_buffer);
  UNUSED(_time_info);
  UNUSED(_flags);
  ErlNifEnv *msg_env;
  ERL_NIF_TERM packet_term;
  size_t packet_size_in_bytes = frames * 2 * 2; // we use 16 bit, 2 channels
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


  if(!enif_send(NULL, &source_handle->destination, msg_env, msg)) {
    MEMBRANE_THREADED_WARN("Capture: packet send failed");
  }

  enif_free_env(msg_env);

  return paContinue;
}


static ERL_NIF_TERM export_start(ErlNifEnv* env, int _argc, const ERL_NIF_TERM argv[]) {
  UNUSED(_argc);
  PaError error;

  MEMBRANE_UTIL_PARSE_RESOURCE_ARG(0, source_handle, SourceHandle, RES_SOURCE_HANDLE_TYPE);

  // Start the stream
  error = Pa_StartStream(source_handle->stream);
  if(error != paNoError) {
    MEMBRANE_WARN(env, "Pa_StartStream: error = %d (%s)", error, Pa_GetErrorText(error));
    return membrane_util_make_error_internal(env, "pa+_start_stream");
  }

  // Return
  return membrane_util_make_ok(env);
}


static ERL_NIF_TERM export_stop(ErlNifEnv* env, int _argc, const ERL_NIF_TERM argv[]) {
  UNUSED(_argc);
  PaError error;

  MEMBRANE_UTIL_PARSE_RESOURCE_ARG(0, source_handle, SourceHandle, RES_SOURCE_HANDLE_TYPE);

  // Stop the stream
  error = Pa_StopStream(source_handle->stream);
  if(error != paNoError) {
    MEMBRANE_WARN(env, "Pa_StartStream: error = %d (%s)", error, Pa_GetErrorText(error));
    return membrane_util_make_error_internal(env, "pa_close_stream");
  }

  // Return
  return membrane_util_make_ok(env);
}


static ERL_NIF_TERM export_create(ErlNifEnv* env, int _argc, const ERL_NIF_TERM argv[]) {
  UNUSED(_argc);
  // char endpoint_id[64];
  SourceHandle *source_handle;
  PaError error;


  // Get device ID arg
  // FIXME it is not going to be an atom
  // if(!enif_get_atom(env, argv[0], (char *) endpoint_id, ENDPOINT_ID_LEN, ERL_NIF_LATIN1)) {
  //   return membrane_util_make_error_args(env, "endpoint_id", "Passed device ID is not valid");
  // }

  MEMBRANE_UTIL_PARSE_PID_ARG(1, destination);
  MEMBRANE_UTIL_PARSE_INT_ARG(2, buffer_size);


  // Initialize handle
  source_handle = (SourceHandle *) enif_alloc_resource(RES_SOURCE_HANDLE_TYPE, sizeof(SourceHandle));
  MEMBRANE_DEBUG(env, "Creating SourceHandle %p", source_handle);

  source_handle->destination = destination;


  // Initialize PortAudio
  error = Pa_Initialize();
  if(error != paNoError) {
    MEMBRANE_WARN(env, "Pa_Initialize: error = %d (%s)", error, Pa_GetErrorText(error));
    return membrane_util_make_error_internal(env, "pa_initialize");
  }


  // Open stream for the default device
  error = Pa_OpenDefaultStream(&(source_handle->stream),
                              2, // 2 input channels
                              0, // no output
                              paInt16, // 16 bit integer format FIXME hardcoded
                              48000, // sample rate FIXME hardcoded
                              buffer_size, // frames per buffer
                              callback, // callback function for processing
                              source_handle); // user data passed to the callback

  if(error != paNoError) {
    MEMBRANE_WARN(env, "Pa_OpenDefaultStream: error = %d (%s)", error, Pa_GetErrorText(error));
    return membrane_util_make_error_internal(env, "pa_open_default_stream");
  }


  // Store handle as an erlang resource
  ERL_NIF_TERM source_handle_term = enif_make_resource(env, source_handle);
  enif_release_resource(source_handle);


  // Return
  return membrane_util_make_ok_tuple(env, source_handle_term);
}


static ErlNifFunc nif_funcs[] = {
  {"create", 3, export_create, 0},
  {"start", 1, export_start, 0},
  {"stop", 1, export_stop, 0}
};


ERL_NIF_INIT(Elixir.Membrane.Element.PortAudio.Source.Native.Nif, nif_funcs, load, NULL, NULL, NULL)
