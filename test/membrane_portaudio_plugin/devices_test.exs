defmodule Membrane.Portaudio.DevicesTest do
  use ExUnit.Case, async: true

  test "list devices" do
    devices = Membrane.PortAudio.list_devices()
    Enum.each(devices, &assert(%Membrane.PortAudio.Device{} = &1))
  end
end
