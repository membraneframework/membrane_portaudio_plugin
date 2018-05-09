defmodule Membrane.Element.PortAudio.Sink do
  @moduledoc """
  Audio sink that plays sound via multi-platform PortAudio library.
  """

  use Membrane.Element.Base.Sink
  alias Membrane.Buffer
  alias __MODULE__.Native
  alias Membrane.Caps.Audio.Raw, as: Caps
  use Membrane.Mixins.Log

  def_known_sink_pads sink:
                        {:always, :pull, {Caps, channels: 2, sample_rate: 48000, format: :s16le}}

  # FIXME: improve endpoint_id option
  def_options endpoint_id: [
                type: :string,
                spec: String.t() | nil,
                default: nil,
                description: "Portaudio sound card id"
              ],
              buffer_size: [
                type: :integer,
                spec: pos_integer,
                default: 256,
                description: "Size of the ringbuffer (in frames)"
              ]

  @impl true
  def handle_init(%__MODULE__{endpoint_id: endpoint_id, buffer_size: buffer_size}) do
    {:ok,
     %{
       endpoint_id: endpoint_id,
       buffer_size: buffer_size,
       native: nil
     }}
  end

  @impl true
  def handle_prepare(:stopped, %{endpoint_id: endpoint_id, buffer_size: buffer_size} = state) do
    with {:ok, native} <- Native.create(endpoint_id, buffer_size, self()) do
      {:ok, %{state | native: native}}
    else
      {:error, reason} -> {{:error, reason}, state}
    end
  end

  @impl true
  def handle_prepare(:playing, state) do
    {:ok, %{state | native: nil}}
  end

  @impl true
  def handle_other({:ringbuffer_demand, size}, state) do
    {{:ok, demand: {:sink, size |> div(state.buffer_size)}}, state}
  end

  @impl true
  def handle_write1(:sink, %Buffer{payload: payload}, _, %{native: native} = state) do
    {Native.write(native, payload), state}
  end
end
