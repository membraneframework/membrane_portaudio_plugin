defmodule Membrane.Element.PortAudio.Source do
  @moduledoc """
  Audio source that captures sound via multi-platform PortAudio library.
  """

  use Membrane.Element.Base.Source
  alias Membrane.Buffer
  alias Membrane.Element.PortAudio.SourceOptions
  alias Membrane.Element.PortAudio.SourceNative

  # FIXME format is hardcoded at the moment
  @supported_caps %Membrane.Caps.Audio.Raw{channels: 2, sample_rate: 48000, format: :s16le}

  def_known_source_pads %{
    :source => {:always, [@supported_caps]}
  }


  # Private API

  @doc false
  def handle_init(%SourceOptions{endpoint_id: endpoint_id, buffer_size: buffer_size}) do
    {:ok, %{
      endpoint_id: endpoint_id,
      buffer_size: buffer_size,
      native: nil,
    }}
  end


  @doc false
  def handle_prepare(:stopped, %{endpoint_id: endpoint_id, buffer_size: buffer_size} = state) do
    case SourceNative.create(endpoint_id, self(), buffer_size) do
      {:ok, native} ->
        {:ok, [
          {:caps, {:source, @supported_caps}}
        ], %{state | native: native}}

      {:error, reason} ->
        {:error, {:create, reason}, state}
    end
  end


  @doc false
  def handle_prepare(:playing, state) do
    {:ok, %{state | native: nil}}
  end


  @doc false
  def handle_play(%{native: native} = state) do
    case SourceNative.start(native) do
      :ok ->
        {:ok, state}

      {:error, reason} ->
        {:error, {:start, reason}, state}
    end
  end


  @doc false
  def handle_stop(%{native: native} = state) do
    case SourceNative.stop(native) do
      :ok ->
        {:ok, state}

      {:error, reason} ->
        {:error, {:stop, reason}, state}
    end
  end


  @doc false
  def handle_other({:membrane_element_portaudio_source_packet, payload}, state) do
    {:ok, [
      {:send, {:source, %Buffer{payload: payload}}},
    ], state}
  end
end
