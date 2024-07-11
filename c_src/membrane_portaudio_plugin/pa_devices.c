#include "pa_devices.h"

UNIFEX_TERM list(UnifexEnv *env) {
  UNIFEX_TERM result;
  Pa_Initialize();
  int num_devices = Pa_GetDeviceCount();
  if (num_devices < 0) {
    char error[2048];
    sprintf(error, "Pa_CountDevices returned error, code: %d", num_devices);
    result = unifex_raise(env, error);
    goto list_error;
  }
  device *devices = unifex_alloc(sizeof(device) * num_devices);
  int default_input_id = Pa_GetDefaultInputDevice();
  int default_output_id = Pa_GetDefaultOutputDevice();
  for (int i = 0; i < num_devices; i++) {
    const PaDeviceInfo *device_info = Pa_GetDeviceInfo(i);

    if (i == default_input_id) {
      devices[i].default_device = DEFAULT_DEVICE_INPUT;
    } else if (i == default_output_id) {
      devices[i].default_device = DEFAULT_DEVICE_OUTPUT;
    } else {
      devices[i].default_device = DEFAULT_DEVICE_FALSE;
    }

    devices[i].name = (char *)device_info->name;
    devices[i].id = i;
    devices[i].max_output_channels = device_info->maxOutputChannels;
    devices[i].max_input_channels = device_info->maxInputChannels;
    devices[i].default_sample_rate = device_info->defaultSampleRate;
  }

  result = list_result(env, devices, num_devices);
list_error:
  Pa_Terminate();
  return result;
}
