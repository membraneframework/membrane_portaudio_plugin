defmodule Membrane.Element.PortAudio.Sink do
  @moduledoc """
  Audio sink that plays sound via multi-platform PortAudio library.
  """

  use Membrane.Element.Base.Sink
  alias Membrane.Element.PortAudio.SinkOptions

  # FIXME format is hardcoded at the moment
  @supported_caps %Membrane.Caps.Audio.Raw{channels: 2, sample_rate: 48000, format: :s16le}


  # Private API

  @doc false
  def potential_sink_pads(), do: %{
    :sink => {:always, [@supported_caps]}
  }


  @doc false
  def handle_init(%SinkOptions{device_id: device_id, buffer_size: buffer_size}) do
    {:ok, %{
      device_id: device_id,
      buffer_size: buffer_size,
      native: nil,
    }}
  end


  @doc false
  def handle_prepare(%{device_id: device_id, buffer_size: buffer_size} = state) do
    case Membrane.Element.PortAudio.SinkNative.create(device_id, buffer_size) do
      {:ok, native} ->
        {:ok, [
          {:send, {:sink, %Membrane.Event.caps(@supported_caps)}}
        ], %{state | native: native}}

      {:error, reason} ->
        {:error, {:create, reason}, state}
    end
  end


  @doc false
  def handle_buffer(%Membrane.Buffer{caps: @supported_caps, payload: payload}, %{native: native} = state) do
    case Membrane.Element.PortAudio.SinkNative.write(native, payload) do
      :ok ->
        {:ok, [], state}

      {:error, reason} ->
        {:error, {:write, reason}, state}
    end
  end
end
