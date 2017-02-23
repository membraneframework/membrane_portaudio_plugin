defmodule Membrane.Element.PortAudio.SinkOptions do
  defstruct \
    endpoint_id: nil,
    buffer_size: 256

  @type t :: %Membrane.Element.PortAudio.SinkOptions{
    endpoint_id: String.t | nil,
    buffer_size: non_neg_integer
  }
end
