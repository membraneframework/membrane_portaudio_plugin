/**
 * Membrane Element: PortAudio - Erlang native interface for portaudio-based sink
 *
 * All Rights Reserved, (c) 2016 Marcin Lewandowski
 */


#include "sink.h"

#define MEMBRANE_LOG_TAG         "Membrane.Element.PortAudio.SinkNative"
#define SAMPLE_SIZE_BYTES        4
#define RINGBUFFER_SIZE_ELEMENTS 4096

ErlNifResourceType *RES_SOURCE_HANDLE_TYPE;


static void res_sink_handle_destructor(ErlNifEnv *env, void *value) {
  PaError error;
  SinkHandle *sink_handle = (SinkHandle *) value;

  MEMBRANE_DEBUG("Destroying SinkHandle %p", value);

  if(Pa_IsStreamStopped(sink_handle->stream) == 0) {
    error = Pa_StopStream(sink_handle->stream);
    if(error != paNoError) {
      MEMBRANE_DEBUG("Pa_StopStream: error = %d (%s)", error, Pa_GetErrorText(error));
    }
  }

  error = Pa_CloseStream(sink_handle->stream);
  if(error != paNoError) {
    MEMBRANE_DEBUG("Pa_CloseStream: error = %d (%s)", error, Pa_GetErrorText(error));
  }

  error = Pa_Terminate();
  if(error != paNoError) {
    MEMBRANE_DEBUG("Pa_Terminate: error = %d (%s)", error, Pa_GetErrorText(error));
  }

  if(sink_handle->ringbuffer_data != NULL) {
    free(sink_handle->ringbuffer_data);
  }

  if(sink_handle->ringbuffer != NULL) {
    free(sink_handle->ringbuffer);
  }
}


static int load(ErlNifEnv *env, void **priv_data, ERL_NIF_TERM load_info) {
  int flags = ERL_NIF_RT_CREATE | ERL_NIF_RT_TAKEOVER;
  RES_SOURCE_HANDLE_TYPE =
    enif_open_resource_type(env, NULL, "SinkHandle", res_sink_handle_destructor, flags, NULL);

  return 0;
}


static int callback(const void *input_buffer, void *output_buffer, unsigned long frames_per_buffer, const PaStreamCallbackTimeInfo* time_info, PaStreamCallbackFlags flags, void *user_data) {
  SinkHandle *sink_handle = (SinkHandle *) user_data;

  ring_buffer_size_t elements_available = PaUtil_GetRingBufferReadAvailable(sink_handle->ringbuffer);
  if(elements_available >= frames_per_buffer) {
    ring_buffer_size_t elements_read = PaUtil_ReadRingBuffer(sink_handle->ringbuffer, output_buffer, frames_per_buffer);
    MEMBRANE_DEBUG("Callback: elements available = %d, elements read = %d, frames per buffer = %lu", elements_available, elements_read, frames_per_buffer);

  } else {
    memset(output_buffer, 0, frames_per_buffer * SAMPLE_SIZE_BYTES);
  }

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


  // Write samples to the ringbuffer
  //
  // We do not do direct write to the stream here because:
  //
  // a) portaudio does not support synchronous API for all types of drivers
  // b) we don't know for how long portaudio is going to consume the data
  //    and if it takes long time erlang scheduler will go crazy.
  //
  // Instead we put the data into ringbuffer and write them in the callback.
  ring_buffer_size_t elements_written = PaUtil_WriteRingBuffer(sink_handle->ringbuffer, payload_binary.data, payload_binary.size / SAMPLE_SIZE_BYTES); // FIXME hardcoded 2 channels, 16 bit
  // MEMBRANE_DEBUG("Write: elements written = %d", elements_written);
  if(elements_written != payload_binary.size / SAMPLE_SIZE_BYTES) {
    // MEMBRANE_DEBUG("Write: written only %d out of %lu bytes into ringbuffer", elements_written * SAMPLE_SIZE_BYTES, payload_binary.size);
    return membrane_util_make_error(env, enif_make_atom(env, "discontinuity"));

  } else {
    return membrane_util_make_ok(env);
  }
}


static ERL_NIF_TERM export_create(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[])
{
  int               buffer_size;
  char              endpoint_id[64];
  SinkHandle       *sink_handle;
  PaError           error;


  // Get device ID arg
  // FIXME it is not going to be an atom
  // if(!enif_get_atom(env, argv[0], (char *) endpoint_id, ENDPOINT_ID_LEN, ERL_NIF_LATIN1)) {
  //   return membrane_util_make_error_args(env, "endpoint_id", "Passed device ID is not valid");
  // }


  // Get buffer size arg
  if(!enif_get_int(env, argv[1], &buffer_size)) {
    return membrane_util_make_error_args(env, "buffer_duration", "Passed buffer size is out of integer range or is not an integer");
  }


  // Initialize handle
  sink_handle = (SinkHandle *) enif_alloc_resource(RES_SOURCE_HANDLE_TYPE, sizeof(SinkHandle));
  MEMBRANE_DEBUG("Creating SinkHandle %p", sink_handle);


  // Initialize ringbuffer
  // FIXME hardcoded format, stereo frame, 16bit
  sink_handle->ringbuffer_data = malloc(SAMPLE_SIZE_BYTES * RINGBUFFER_SIZE_ELEMENTS);
  sink_handle->ringbuffer = malloc(sizeof(PaUtilRingBuffer));
  if(PaUtil_InitializeRingBuffer(sink_handle->ringbuffer, SAMPLE_SIZE_BYTES, RINGBUFFER_SIZE_ELEMENTS, sink_handle->ringbuffer_data) == -1) {
    MEMBRANE_DEBUG("PaUtil_InitializeRingBuffer: error = %d (%s)", error, Pa_GetErrorText(error));
    enif_free(sink_handle);
    return membrane_util_make_error_internal(env, "pautilinitializeringbuffer");
  }


  // Initialize PortAudio
  error = Pa_Initialize();
  if(error != paNoError) {
    MEMBRANE_DEBUG("Pa_Initialize: error = %d (%s)", error, Pa_GetErrorText(error));
    enif_free(sink_handle);
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
    MEMBRANE_DEBUG("Pa_OpenDefaultStream: error = %d (%s)", error, Pa_GetErrorText(error));
    enif_free(sink_handle);
    return membrane_util_make_error_internal(env, "paopendefaultstream");
  }


  // Start the stream
  error = Pa_StartStream(sink_handle->stream);
  if(error != paNoError) {
    MEMBRANE_DEBUG("Pa_StartStream: error = %d (%s)", error, Pa_GetErrorText(error));
    enif_free(sink_handle);
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
