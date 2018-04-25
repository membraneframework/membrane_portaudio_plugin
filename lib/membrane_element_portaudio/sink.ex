defmodule Membrane.Element.PortAudio.Sink do
  @moduledoc """
  Audio sink that plays sound via multi-platform PortAudio library.
  """

  use Membrane.Element.Base.Sink
  alias Membrane.Buffer
  alias __MODULE__.Native
  alias Membrane.Element.PortAudio.SinkOptions
  alias Membrane.Caps.Audio.Raw, as: Caps
  use Membrane.Mixins.Log

  def_known_sink_pads sink: {:always, :pull, {Caps, channels: 2, sample_rate: 48000, format: :s16le}}

  # Private API

  @impl true
  def handle_init(%SinkOptions{endpoint_id: endpoint_id, buffer_size: buffer_size}) do
    {:ok, %{
      endpoint_id: endpoint_id,
      buffer_size: buffer_size,
      native: nil,
    }}
  end


  @impl true
  def handle_prepare(:stopped, %{endpoint_id: endpoint_id, buffer_size: buffer_size} = state) do
    with {:ok, native} <- Native.create(endpoint_id, buffer_size, self())
    do {:ok, {[
          # {:caps, {:sink, @supported_caps}} # WTF?
        ], %{state | native: native}}}
    else {:error, reason} -> {:error, {:create, reason}, state}
    end
  end


  @impl true
  def handle_prepare(:playing, state) do
    {:ok, {[], %{state | native: nil}}}
  end

  @impl true
  def handle_other({:ringbuffer_demand, size} = msg, state) do
    debug inspect msg
    {:ok, {[{:demand, {:sink, size |> div(state.buffer_size)}}], state}}
  end


  @impl true
  def handle_write1(:sink, %Buffer{payload: payload}, _, %{native: native} = state) do
    with :ok <- Native.write(native, payload)
    do {:ok, {[], state}}
    else {:error, reason} -> {:error, {:write, reason}, state}
    end
  end
end
