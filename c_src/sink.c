/**
 * Membrane Element: PortAudio - Erlang native interface for portaudio-based sink
 *
 * All Rights Reserved, (c) 2016 Marcin Lewandowski
 */


#include "sink.h"

#define MEMBRANE_LOG_TAG  "Membrane.Element.PortAudio.SinkNative"


ErlNifResourceType *RES_SOURCE_HANDLE_TYPE;


static void res_sink_handle_destructor(ErlNifEnv *env, void *value) {
  PaError error;
  SinkHandle *sink_handle = (SinkHandle *) value;

  MEMBRANE_DEBUG("Destroying SinkHandle %p", value);

  if(Pa_IsStreamStopped(sink_handle->stream) == 0) {
    error = Pa_StopStream(sink_handle->stream);
    if(error != paNoError) {
      MEMBRANE_DEBUG("Pa_StopStream: error = %d", error);
    }
  }

  error = Pa_CloseStream(sink_handle->stream);
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
    enif_open_resource_type(env, NULL, "SinkHandle", res_sink_handle_destructor, flags, NULL);

  return 0;
}


static int callback(const void *input_buffer, void *output_buffer, unsigned long frames, const PaStreamCallbackTimeInfo* time_info, PaStreamCallbackFlags flags, void *user_data) {
  SinkHandle *sink_handle = (SinkHandle *) user_data;
  int        *out         = (int *) output_buffer;


  return paContinue;
}


static ERL_NIF_TERM export_write(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[])
{
  SinkHandle *sink_handle;
  PaError error;
  ErlNifBinary payload_binary;


  // Get sink_handle arg
  if(!enif_get_resource(env, argv[0], RES_SOURCE_HANDLE_TYPE, (void **) &sink_handle)) {
    return membrane_util_make_error_args(env, "sink_handle", "Passed sink_handle is not valid resource");
  }


  // Get payload arg
  if(!enif_inspect_binary(env, argv[1], &payload_binary)) {
    return membrane_util_make_error_args(env, "payload", "Passed payload is not valid binary");
  }


  // Write samples
  error = Pa_WriteStream(sink_handle->stream, payload_binary.data, payload_binary.size / 4); // FIXME hardcoded 2 channels, 16 bit
  if(error != paNoError) {
    MEMBRANE_DEBUG("Pa_WriteStream: error = %d", error);
    return membrane_util_make_error_internal(env, "pawritestream");
  }


  // Return
  return membrane_util_make_ok(env);
}


static ERL_NIF_TERM export_create(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[])
{
  int             buffer_size;
  char            device_id[64];
  SinkHandle      *sink_handle;
  PaError         error;


  // Get device ID arg
  // FIXME it is not going to be an atom
  // if(!enif_get_atom(env, argv[0], (char *) device_id, ENDPOINT_ID_LEN, ERL_NIF_LATIN1)) {
  //   return membrane_util_make_error_args(env, "device_id", "Passed device ID is not valid");
  // }


  // Get buffer size arg
  if(!enif_get_int(env, argv[1], &buffer_size)) {
    return membrane_util_make_error_args(env, "buffer_duration", "Passed buffer size is out of integer range or is not an integer");
  }


  // Initialize handle
  sink_handle = (SinkHandle *) enif_alloc_resource(RES_SOURCE_HANDLE_TYPE, sizeof(SinkHandle));
  MEMBRANE_DEBUG("Creating SinkHandle %p", sink_handle);


  // Initialize PortAudio
  error = Pa_Initialize();
  if(error != paNoError) {
    MEMBRANE_DEBUG("Pa_Initialize: error = %d", error);
    return membrane_util_make_error_internal(env, "painitialize");
  }


  // Open stream for the default device
  error = Pa_OpenDefaultStream(&(sink_handle->stream),
                              0,              // no input
                              2,              // 2 output channels
                              paInt16,        // 16 bit integer format FIXME hardcoded
                              48000,          // sample rate FIXME hardcoded
                              buffer_size,    // frames per buffer
                              callback,       // callback function for processing
                              sink_handle);   // user data passed to the callback

  if(error != paNoError) {
    MEMBRANE_DEBUG("Pa_OpenDefaultStream: error = %d", error);
    return membrane_util_make_error_internal(env, "paopendefaultstream");
  }


  // Start the stream
  error = Pa_StartStream(sink_handle->stream);
  if(error != paNoError) {
    MEMBRANE_DEBUG("Pa_StartStream: error = %d", error);
    return membrane_util_make_error_internal(env, "pastartstream");
  }


  // Store handle as an erlang resource
  ERL_NIF_TERM sink_handle_term = enif_make_resource(env, sink_handle);
  enif_release_resource(sink_handle);


  // Return
  return membrane_util_make_ok_tuple(env, sink_handle_term);
}


static ErlNifFunc nif_funcs[] =
{
  {"create", 2, export_create},
  {"write", 2, export_write}
};


ERL_NIF_INIT(Elixir.Membrane.Element.PortAudio.SinkNative, nif_funcs, load, NULL, NULL, NULL)
