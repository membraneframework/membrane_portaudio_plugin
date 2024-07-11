module Membrane.PortAudio.Devices

type(
  device :: %Membrane.PortAudio.Device{
    id: int,
    name: string,
    max_input_channels: int,
    max_output_channels: int,
    default_sample_rate: float,
    default_device: default_device
  }
)

type(default_device :: false | :input | :output)
spec list() :: devices :: [device]
