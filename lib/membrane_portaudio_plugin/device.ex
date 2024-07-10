defmodule Membrane.PortAudio.Device do
  @moduledoc """
  Struct carrying information about an audio device.

  See `Membrane.PortAudio.list_devices/0` and `Membrane.PortAudio.print_devices/0`.
  """

  @type t :: %__MODULE__{
          id: non_neg_integer(),
          name: String.t(),
          max_input_channels: non_neg_integer(),
          max_output_channels: non_neg_integer(),
          default_device: false | :input | :output,
          default_sample_rate: float()
        }

  @enforce_keys [
    :id,
    :name,
    :max_input_channels,
    :max_output_channels,
    :default_device,
    :default_sample_rate
  ]

  defstruct @enforce_keys
end
