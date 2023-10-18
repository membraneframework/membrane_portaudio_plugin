#include "pa_devices.h"

UNIFEX_TERM list(UnifexEnv *env) {
  Pa_Initialize();
  int numDevices = Pa_GetDeviceCount();
  if (numDevices < 0) {
    printf("\nERROR: Pa_CountDevices returned 0x%x\n", numDevices);
    return list_result(env);
  } else if (numDevices == 0) {
    printf("\nNo audio devices found\n");
  } else {
    printf("\nAvailable audio devices:\n\n");
    int default_input_id = Pa_GetDefaultInputDevice();
    int default_output_id = Pa_GetDefaultOutputDevice();
    for (int i = 0; i < numDevices; i++) {
      const PaDeviceInfo *device_info = Pa_GetDeviceInfo(i);
      const char *default_str =
          i == default_input_id
              ? " (default input)"
              : i == default_output_id ? " (default output)" : "";

      printf("%s%s\r\n\tid: %d\r\n\tmax_input_channels: "
             "%d\r\n\tmax_output_channels: %d\r\n\n",
             device_info->name, default_str, i, device_info->maxInputChannels,
             device_info->maxOutputChannels);
    }
  }

  Pa_Terminate();
  return list_result(env);
}
