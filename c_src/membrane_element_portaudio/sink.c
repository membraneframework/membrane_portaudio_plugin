#include "sink.h"
#define MEMBRANE_LOG_TAG "Membrane.Element.PortAudio.Sink.Native"
#include <membrane/log.h>

#define FRAME_SIZE 4 // FIXME hardcoded format, stereo frame, 16bit

#define UNUSED(x) (void)(x)


void res_sink_handle_destructor(ErlNifEnv *env, void *value) {
  SinkHandle *handle = (SinkHandle *) value;
  if(handle->is_zombie) return;

  MEMBRANE_DEBUG(env, "Destroying SinkHandle %p", value);

  destroy_pa(env, MEMBRANE_LOG_TAG, handle->stream);

  if(handle->ringbuffer) {
    membrane_ringbuffer_destroy(handle->ringbuffer);
  }
}

static void send_demand(unsigned int size, ErlNifPid demand_handler) {
  ErlNifEnv* msg_env = enif_alloc_env();

  ERL_NIF_TERM tuple[2] = {
    enif_make_atom(msg_env, "membrane_element_portaudio_ringbuffer_demand"),
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
  SinkHandle *handle = (SinkHandle *) user_data;

  size_t elements_available = membrane_ringbuffer_get_read_available(handle->ringbuffer);
  if(elements_available >= frames_per_buffer) {
    size_t elements_read = membrane_ringbuffer_read(handle->ringbuffer, output_buffer, frames_per_buffer);
    MEMBRANE_THREADED_DEBUG("Callback: elements available = %d, elements read = %d, frames per buffer = %lu", elements_available, elements_read, frames_per_buffer);
    send_demand(elements_read*FRAME_SIZE, handle->demand_handler);
  } else {
    memset(output_buffer, 0, frames_per_buffer * FRAME_SIZE);
  }

  return paContinue;
}


ERL_NIF_TERM export_write(ErlNifEnv* env, int _argc, const ERL_NIF_TERM argv[]) {
  UNUSED(_argc);

  MEMBRANE_UTIL_PARSE_RESOURCE_ARG(0, handle, SinkHandle, RES_SINK_HANDLE_TYPE);
  MEMBRANE_UTIL_PARSE_BINARY_ARG(1, payload_binary);

  size_t elements_written = membrane_ringbuffer_write(handle->ringbuffer, payload_binary.data, payload_binary.size / FRAME_SIZE);
  // MEMBRANE_DEBUG(env, "Write: elements written = %d", elements_written);
  if(elements_written != payload_binary.size / FRAME_SIZE) {
    MEMBRANE_WARN(env, "Write: written only %d out of %lu bytes into ringbuffer", elements_written * FRAME_SIZE, payload_binary.size);
  }
  return membrane_util_make_ok(env);
}

ERL_NIF_TERM export_sink_create(ErlNifEnv* env, int _argc, const ERL_NIF_TERM argv[]) {
  UNUSED(_argc);

  MEMBRANE_UTIL_PARSE_PID_ARG(0, demand_handler);
  MEMBRANE_UTIL_PARSE_INT_ARG(1, endpoint_id);
  MEMBRANE_UTIL_PARSE_INT_ARG(2, ringbuffer_size);
  MEMBRANE_UTIL_PARSE_INT_ARG(3, pa_buffer_size);
  MEMBRANE_UTIL_PARSE_ATOM_ARG(4, latency_str, 255);

  MEMBRANE_DEBUG(env, "initializing");

  MembraneRingBuffer* ringbuffer = membrane_ringbuffer_new(ringbuffer_size, FRAME_SIZE);
  if(!ringbuffer) {
    MEMBRANE_WARN(env, "Error initializing ringbuffer");
    return membrane_util_make_error_internal(env, "ringbuffer_init");
  }

  send_demand(ringbuffer_size*FRAME_SIZE, demand_handler);

  SinkHandle* handle = enif_alloc_resource(RES_SINK_HANDLE_TYPE, sizeof(SinkHandle));
  handle->is_zombie = 0;
  handle->ringbuffer = ringbuffer;
  handle->demand_handler = demand_handler;
  handle->stream = NULL;

  char* error = init_pa(
    env,
    MEMBRANE_LOG_TAG,
    1, //direction
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


ERL_NIF_TERM export_sink_destroy(ErlNifEnv* env, int _argc, const ERL_NIF_TERM argv[]) {
  UNUSED(_argc);

  MEMBRANE_UTIL_PARSE_RESOURCE_ARG(0, handle, SinkHandle, RES_SINK_HANDLE_TYPE);

  if(!handle->is_zombie) {

    destroy_pa(env, MEMBRANE_LOG_TAG, handle->stream);
    handle->stream = NULL;

    if(handle->ringbuffer) {
      membrane_ringbuffer_destroy(handle->ringbuffer);
      handle->ringbuffer = NULL;
    }

    handle->is_zombie = 1;
  }

  return membrane_util_make_ok(env);
}
