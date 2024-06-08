module Membrane.PortAudio.Devices

type(
  device :: %Device{
    id: int,
    name: string,
    max_input_channels: int,
    max_output_channels: int,
    is_default: bool
  }
)

spec list() :: {:ok :: label, devices :: [device]}
