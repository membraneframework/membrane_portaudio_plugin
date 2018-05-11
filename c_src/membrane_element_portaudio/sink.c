/**
 * Membrane Element: PortAudio - Erlang native interface for portaudio-based sink
 *
 * All Rights Reserved, (c) 2016 Marcin Lewandowski
 */


#include "sink.h"

#define SAMPLE_SIZE_BYTES        4
#define RINGBUFFER_SIZE_ELEMENTS 4096

#define UNUSED(x) (void)(x)

ErlNifResourceType *RES_SOURCE_HANDLE_TYPE;


static void res_sink_handle_destructor(ErlNifEnv *env, void *value) {
  PaError error;
  SinkHandle *sink_handle = (SinkHandle *) value;

  MEMBRANE_DEBUG(env, "Destroying SinkHandle %p", value);

  if(Pa_IsStreamStopped(sink_handle->stream) == 0) {
    error = Pa_StopStream(sink_handle->stream);
    if(error != paNoError) {
      MEMBRANE_WARN(env, "Pa_StopStream: error = %d (%s)", error, Pa_GetErrorText(error));
    }
  }

  error = Pa_CloseStream(sink_handle->stream);
  if(error != paNoError) {
    MEMBRANE_WARN(env, "Pa_CloseStream: error = %d (%s)", error, Pa_GetErrorText(error));
  }

  error = Pa_Terminate();
  if(error != paNoError) {
    MEMBRANE_WARN(env, "Pa_Terminate: error = %d (%s)", error, Pa_GetErrorText(error));
  }

  if(sink_handle->ringbuffer) {
    membrane_ringbuffer_destroy(sink_handle->ringbuffer);
  }
}


static int load(ErlNifEnv *env, void **_priv_data, ERL_NIF_TERM _load_info) {
  UNUSED(_priv_data);
  UNUSED(_load_info);
  int flags = ERL_NIF_RT_CREATE | ERL_NIF_RT_TAKEOVER;
  RES_SOURCE_HANDLE_TYPE =
    enif_open_resource_type(env, NULL, "SinkHandle", res_sink_handle_destructor, flags, NULL);

  return 0;
}

static void send_demand(unsigned int size, ErlNifPid* demand_handler) {
  ErlNifEnv* msg_env = enif_alloc_env();

  ERL_NIF_TERM tuple[2] = {
    enif_make_atom(msg_env, "ringbuffer_demand"),
    enif_make_int(msg_env, (int)size),
  };
  ERL_NIF_TERM msg = enif_make_tuple_from_array(msg_env, tuple, 2);

  if(!enif_send(NULL, demand_handler, msg_env, msg)) {
    MEMBRANE_THREADED_WARN("PortAudio sink: failed to send demand");
  }

  enif_free_env(msg_env);
}


static int callback(const void *_input_buffer, void *output_buffer, unsigned long frames_per_buffer, const PaStreamCallbackTimeInfo* _time_info, PaStreamCallbackFlags _flags, void *user_data) {
  UNUSED(_input_buffer);
  UNUSED(_time_info);
  UNUSED(_flags);
  SinkHandle *sink_handle = (SinkHandle *) user_data;

  size_t elements_available = membrane_ringbuffer_get_read_available(sink_handle->ringbuffer);
  if(elements_available >= frames_per_buffer) {
    size_t elements_read = membrane_ringbuffer_read(sink_handle->ringbuffer, output_buffer, frames_per_buffer);
    MEMBRANE_THREADED_DEBUG("Callback: elements available = %d, elements read = %d, frames per buffer = %lu", elements_available, elements_read, frames_per_buffer);
    send_demand(elements_read, sink_handle->demand_handler);
  } else {
    memset(output_buffer, 0, frames_per_buffer * SAMPLE_SIZE_BYTES);
  }

  return paContinue;
}


static ERL_NIF_TERM export_write(ErlNifEnv* env, int _argc, const ERL_NIF_TERM argv[]) {
  UNUSED(_argc);
  SinkHandle *sink_handle;
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
  size_t elements_written = membrane_ringbuffer_write(sink_handle->ringbuffer, payload_binary.data, payload_binary.size / SAMPLE_SIZE_BYTES); // FIXME hardcoded 2 channels, 16 bit
  // MEMBRANE_DEBUG(env, "Write: elements written = %d", elements_written);
  if(elements_written != payload_binary.size / SAMPLE_SIZE_BYTES) {
    MEMBRANE_WARN(env, "Write: written only %d out of %lu bytes into ringbuffer", elements_written * SAMPLE_SIZE_BYTES, payload_binary.size);
    return membrane_util_make_error(env, enif_make_atom(env, "discontinuity"));

  } else {
    return membrane_util_make_ok(env);
  }
}


static ERL_NIF_TERM export_create(ErlNifEnv* env, int _argc, const ERL_NIF_TERM argv[]) {
  UNUSED(_argc);
  int               buffer_size;
  ErlNifPid*        demand_handler = (ErlNifPid*) enif_alloc(sizeof(ErlNifPid));
  // char              endpoint_id[64];
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
  if(!enif_get_local_pid(env, argv[2], demand_handler)) {
    return membrane_util_make_error_args(env, "demand_handler", "Passed demand_handler is not a valid pid");
  }

  // Initialize handle
  sink_handle = (SinkHandle *) enif_alloc_resource(RES_SOURCE_HANDLE_TYPE, sizeof(SinkHandle));
  MEMBRANE_DEBUG(env, "Creating SinkHandle %p", sink_handle);

  sink_handle->demand_handler = demand_handler;

  // Initialize ringbuffer
  // FIXME hardcoded format, stereo frame, 16bit
  sink_handle->ringbuffer = membrane_ringbuffer_new(RINGBUFFER_SIZE_ELEMENTS, SAMPLE_SIZE_BYTES);
  if(!sink_handle->ringbuffer) {
    MEMBRANE_WARN(env, "Error initializing ringbuffer");
    enif_free(sink_handle);
    return membrane_util_make_error_internal(env, "ringbuffer_init");
  }
  // if(PaUtil_InitializeRingBuffer(sink_handle->ringbuffer, SAMPLE_SIZE_BYTES, RINGBUFFER_SIZE_ELEMENTS, sink_handle->ringbuffer_data) == -1) {
  //   MEMBRANE_WARN(env, "PaUtil_InitializeRingBuffer: error = %d (%s)", error, Pa_GetErrorText(error));
  //   enif_free(sink_handle);
  //   return membrane_util_make_error_internal(env, "pautilinitializeringbuffer");
  // }


  // Initialize PortAudio
  error = Pa_Initialize();
  if(error != paNoError) {
    MEMBRANE_WARN(env, "Pa_Initialize: error = %d (%s)", error, Pa_GetErrorText(error));
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
    MEMBRANE_WARN(env, "Pa_OpenDefaultStream: error = %d (%s)", error, Pa_GetErrorText(error));
    enif_free(sink_handle);
    return membrane_util_make_error_internal(env, "paopendefaultstream");
  }


  // Start the stream
  error = Pa_StartStream(sink_handle->stream);
  if(error != paNoError) {
    MEMBRANE_WARN(env, "Pa_StartStream: error = %d (%s)", error, Pa_GetErrorText(error));
    enif_free(sink_handle);
    return membrane_util_make_error_internal(env, "pastartstream");
  }


  send_demand(RINGBUFFER_SIZE_ELEMENTS, sink_handle->demand_handler);

  // Store handle as an erlang resource
  ERL_NIF_TERM sink_handle_term = enif_make_resource(env, sink_handle);
  enif_release_resource(sink_handle);


  // Return
  return membrane_util_make_ok_tuple(env, sink_handle_term);
}


static ErlNifFunc nif_funcs[] = {
  {"create", 3, export_create, 0},
  {"write", 2, export_write, 0}
};


ERL_NIF_INIT(Elixir.Membrane.Element.PortAudio.Sink.Native.Nif, nif_funcs, load, NULL, NULL, NULL)
