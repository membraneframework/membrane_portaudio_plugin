#include "pa_devices.h"

UNIFEX_TERM list(UnifexEnv *env)
{
  Pa_Initialize();
  int numDevices = Pa_GetDeviceCount();
  device devices[numDevices];
  if (numDevices < 0)
  {
    printf("\nERROR: Pa_CountDevices returned 0x%x\n", numDevices);
    return list_result(env, devices, numDevices);
  }
  else if (numDevices == 0)
  {
    return list_result(env, devices, numDevices);
  }
  else
  {
    int default_input_id = Pa_GetDefaultInputDevice();
    int default_output_id = Pa_GetDefaultOutputDevice();
    for (int i = 0; i < numDevices; i++)
    {
      const PaDeviceInfo *device_info = Pa_GetDeviceInfo(i);

      if (i == default_input_id)
      {
        devices[i].default_device = DEFAULT_DEVICE_INPUT;
      }
      else if (i == default_output_id)
      {
        devices[i].default_device = DEFAULT_DEVICE_OUTPUT;
      }
      else
      {
        devices[i].default_device = DEFAULT_DEVICE_FALSE;
      }

      devices[i].name = malloc(strlen(device_info->name) + 1);
      if (device_info->name != NULL)
      {
        strcpy(devices[i].name, device_info->name);
      }

      devices[i].max_output_channels = device_info->maxOutputChannels;
      devices[i].max_input_channels = device_info->maxInputChannels;
      devices[i].default_sample_rate = device_info->defaultSampleRate;
    }
  }

  Pa_Terminate();
  return list_result(env, devices, numDevices);
}
