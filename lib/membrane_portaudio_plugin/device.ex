defmodule Membrane.PortAudio.Device do
  defstruct [
    :id,
    :name,
    :max_input_channels,
    :max_output_channels,
    :is_default,
    :default_sample_rate
  ]
end
