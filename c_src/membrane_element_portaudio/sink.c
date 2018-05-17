/**
 * Membrane Element: PortAudio - Erlang native interface for portaudio-based sink
 *
 * All Rights Reserved, (c) 2016 Marcin Lewandowski
 */


#include "sink.h"

#define FRAME_SIZE 4 // FIXME hardcoded format, stereo frame, 16bit

#define UNUSED(x) (void)(x)

ErlNifResourceType *RES_SINK_HANDLE_TYPE;


static void res_sink_handle_destructor(ErlNifEnv *env, void *value) {
  PaError error;
  SinkHandle *sink_handle = (SinkHandle *) value;

  MEMBRANE_DEBUG(env, "Destroying SinkHandle %p", value);

  if(sink_handle->stream) {
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
  RES_SINK_HANDLE_TYPE =
    enif_open_resource_type(env, NULL, "SinkHandle", res_sink_handle_destructor, flags, NULL);

  return 0;
}


static void send_demand(unsigned int size, ErlNifPid demand_handler) {
  ErlNifEnv* msg_env = enif_alloc_env();

  ERL_NIF_TERM tuple[2] = {
    enif_make_atom(msg_env, "ringbuffer_demand"),
    enif_make_int(msg_env, (int)size),
  };
  ERL_NIF_TERM msg = enif_make_tuple_from_array(msg_env, tuple, 2);

  if(!enif_send(NULL, &demand_handler, msg_env, msg)) {
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
    memset(output_buffer, 0, frames_per_buffer * FRAME_SIZE);
  }

  return paContinue;
}


static ERL_NIF_TERM export_write(ErlNifEnv* env, int _argc, const ERL_NIF_TERM argv[]) {
  UNUSED(_argc);

  MEMBRANE_UTIL_PARSE_RESOURCE_ARG(0, sink_handle, SinkHandle, RES_SINK_HANDLE_TYPE);
  MEMBRANE_UTIL_PARSE_BINARY_ARG(1, payload_binary);

  size_t elements_written = membrane_ringbuffer_write(sink_handle->ringbuffer, payload_binary.data, payload_binary.size / FRAME_SIZE);
  // MEMBRANE_DEBUG(env, "Write: elements written = %d", elements_written);
  if(elements_written != payload_binary.size / FRAME_SIZE) {
    MEMBRANE_WARN(env, "Write: written only %d out of %lu bytes into ringbuffer", elements_written * FRAME_SIZE, payload_binary.size);
    return membrane_util_make_error(env, enif_make_atom(env, "discontinuity"));
  } else {
    return membrane_util_make_ok(env);
  }
}


static char* init_pa_stream(
  ErlNifEnv* env, PaStream** stream, void* handle, PaSampleFormat sample_format,
  int sample_rate, int channels, char* latency_str, int pa_buffer_size,
  PaDeviceIndex endpoint_id
) {
  PaError error;

  error = Pa_Initialize();
  if(error != paNoError) {
    MEMBRANE_WARN(env, "Pa_Initialize: error = %d (%s)", error, Pa_GetErrorText(error));
    return "pa_initialize";
  }

  const PaDeviceInfo* device_info = Pa_GetDeviceInfo(endpoint_id);
  if(!device_info) {
    MEMBRANE_WARN(env, "Invalid endpoint id: %d", endpoint_id);
    return "invalid_endpoint_id";
  }

  PaTime latency;
  if(!strcmp(latency_str, "high")) latency = device_info->defaultHighOutputLatency;
  else if (!strcmp(latency_str, "low")) latency = device_info->defaultLowOutputLatency;
  else {
    MEMBRANE_WARN(env, "Invalid latency: %s", latency_str);
    return "invalid_latency";
  }

  PaStreamParameters stream_params = {
    .device = endpoint_id,
    .channelCount = channels,
    .sampleFormat = sample_format,
    .suggestedLatency = latency,
    .hostApiSpecificStreamInfo = NULL
  };

  error = Pa_OpenStream(
    stream,
    NULL, // no input
    &stream_params, // output stream params
    sample_rate,
    pa_buffer_size,
    0, // PaStreamFlags
    callback,
    handle // passed to the callback
  );

  if(error != paNoError) {
    MEMBRANE_WARN(env, "Pa_OpenStream: error = %d (%s)", error, Pa_GetErrorText(error));
    return "pa_open_stream";
  }

  error = Pa_StartStream(*stream);
  if(error != paNoError) {
    MEMBRANE_WARN(env, "Pa_StartStream: error = %d (%s)", error, Pa_GetErrorText(error));
    return "pa_start_stream";
  }

  return NULL;
}


static ERL_NIF_TERM export_create(ErlNifEnv* env, int _argc, const ERL_NIF_TERM argv[]) {
  UNUSED(_argc);

  MEMBRANE_UTIL_PARSE_INT_ARG(0, endpoint_id);
  MEMBRANE_UTIL_PARSE_INT_ARG(1, pa_buffer_size);
  MEMBRANE_UTIL_PARSE_PID_ARG(2, demand_handler);
  MEMBRANE_UTIL_PARSE_ATOM_ARG(3, latency_str, 255);


  MembraneRingBuffer* ringbuffer = membrane_ringbuffer_new(4096, FRAME_SIZE);
  if(!ringbuffer) {
    MEMBRANE_WARN(env, "Error initializing ringbuffer");
    return membrane_util_make_error_internal(env, "ringbuffer_init");
  }

  send_demand(pa_buffer_size*FRAME_SIZE, demand_handler);

  SinkHandle* sink_handle = enif_alloc_resource(RES_SINK_HANDLE_TYPE, sizeof(SinkHandle));
  sink_handle->ringbuffer = ringbuffer;
  sink_handle->demand_handler = demand_handler;
  sink_handle->stream = NULL;

  char* error = init_pa_stream(
    env,
    &(sink_handle->stream),
    sink_handle,
    paInt16, //sample format #FIXME hardcoded0
    48000, //sample rate #FIXME hardcoded
    2, //channels #FIXME hardcoded
    latency_str,
    pa_buffer_size,
    endpoint_id
  );

  if(error) {
    enif_release_resource(sink_handle);
    return membrane_util_make_error_internal(env, error);
  }

  ERL_NIF_TERM sink_handle_term = enif_make_resource(env, sink_handle);
  enif_release_resource(sink_handle);

  return membrane_util_make_ok_tuple(env, sink_handle_term);
}


static ERL_NIF_TERM export_get_default_endpoint_id(ErlNifEnv* env, int _argc, const ERL_NIF_TERM _argv[]) {
  UNUSED(_argc);
  UNUSED(_argv);
  return enif_make_int(env, Pa_GetDefaultOutputDevice());
}


static ErlNifFunc nif_funcs[] = {
  {"create", 4, export_create, 0},
  {"write", 2, export_write, 0},
  {"get_default_endpoint_id", 0, export_get_default_endpoint_id, 0}
};


ERL_NIF_INIT(Elixir.Membrane.Element.PortAudio.Sink.Native.Nif, nif_funcs, load, NULL, NULL, NULL)
