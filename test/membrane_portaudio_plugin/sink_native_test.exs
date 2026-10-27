defmodule Membrane.PortAudio.Sink.NativeTest do
  use ExUnit.Case, async: true

  alias Membrane.PortAudio.Sink.Native

  test "create rejects non-positive buffer sizes" do
    for {channels, ringbuffer_size, pa_buffer_size} <- [{2, 0, 256}, {2, -1, 256}, {0, 4096, 256}] do
      assert {:error, :invalid_buffer_size} =
               Native.create(
                 self(),
                 self(),
                 -1,
                 48_000,
                 channels,
                 :s16le,
                 ringbuffer_size,
                 pa_buffer_size,
                 :high
               )
    end
  end
end
