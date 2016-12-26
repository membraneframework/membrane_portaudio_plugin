defmodule Membrane.Element.PortAudio.SourceOptions do
  defstruct \
    device_id: nil,
    buffer_size: 256

  @type t :: %Membrane.Element.PortAudio.SourceOptions{
    device_id: String.t | nil,
    buffer_size: non_neg_integer
  }
end
