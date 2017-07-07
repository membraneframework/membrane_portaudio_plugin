defmodule Membrane.Element.PortAudio.Sink do
  @moduledoc """
  Audio sink that plays sound via multi-platform PortAudio library.
  """

  use Membrane.Element.Base.Sink
  alias Membrane.Buffer
  alias Membrane.Element.PortAudio.SinkNative
  alias Membrane.Element.PortAudio.SinkOptions

  # FIXME format is hardcoded at the moment
  @supported_caps %Membrane.Caps.Audio.Raw{channels: 2, sample_rate: 48000, format: :s16le}

  def_known_sink_pads %{
    :sink => {:always, [@supported_caps]}
  }


  # Private API

  @doc false
  def handle_init(%SinkOptions{endpoint_id: endpoint_id, buffer_size: buffer_size}) do
    {:ok, %{
      endpoint_id: endpoint_id,
      buffer_size: buffer_size,
      native: nil,
    }}
  end


  @doc false
  def handle_prepare(:stopped, %{endpoint_id: endpoint_id, buffer_size: buffer_size} = state) do
    case SinkNative.create(endpoint_id, buffer_size) do
      {:ok, native} ->
        {:ok, [
          # {:caps, {:sink, @supported_caps}}
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
  def handle_buffer(:sink, _caps, %Buffer{payload: payload}, %{native: native} = state) do
    case SinkNative.write(native, payload) do
      :ok ->
        {:ok, [], state}

      {:error, reason} ->
        {:error, {:write, reason}, state}
    end
  end
end
