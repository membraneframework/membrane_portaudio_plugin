defmodule Membrane.Element.PortAudio.Source do
  @moduledoc """
  Audio source that captures sound via multi-platform PortAudio library.
  """

  use Membrane.Element.Base.Source
  alias Membrane.Element.PortAudio.SourceOptions


  # FIXME format is hardcoded at the moment
  @supported_caps %Membrane.Caps.Audio.Raw{channels: 2, sample_rate: 48000, format: :s16le}


  # Private API

  @doc false
  def potential_source_pads(), do: %{
    :source => {:always, [@supported_caps]}
  }


  @doc false
  def handle_init(%SourceOptions{device_id: device_id, buffer_size: buffer_size}) do
    {:ok, %{
      device_id: device_id,
      buffer_size: buffer_size,
      native: nil,
    }}
  end


  @doc false
  def handle_prepare(%{device_id: device_id, buffer_size: buffer_size} = state) do
    case Membrane.Element.PortAudio.SourceNative.create(device_id, self(), buffer_size) do
      {:ok, native} ->
        {:ok, [
          {:send, {:source, %Membrane.Event.caps(@supported_caps)}}
        ], %{state | native: native}}

      {:error, reason} ->
        {:error, {:create, reason}, state}
    end
  end


  @doc false
  def handle_play(%{native: native} = state) do
    case Membrane.Element.PortAudio.SourceNative.start(native) do
      :ok ->
        {:ok, state}

      {:error, reason} ->
        {:error, {:start, reason}, state}
    end
  end


  @doc false
  def handle_stop(%{native: native} = state) do
    case Membrane.Element.PortAudio.SourceNative.stop(native) do
      :ok ->
        {:ok, state}

      {:error, reason} ->
        {:error, {:stop, reason}, state}
    end
  end


  @doc false
  def handle_other({:membrane_element_portaudio_source_packet, payload}, state) do
    {:ok, [
      {:send, :source, [%Membrane.Buffer{caps: @supported_caps, payload: payload}}]},
    ], state}
  end
end
