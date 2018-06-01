defmodule Membrane.Element.PortAudio.Sink do
  @moduledoc """
  Audio sink that plays sound via multi-platform PortAudio library.
  """

  use Membrane.Element.Base.Sink
  alias Membrane.Buffer
  alias Membrane.Caps.Audio.Raw, as: Caps
  use Membrane.Mixins.Log

  @native Mockery.of(Membrane.Element.PortAudio.Native)

  @pa_no_device -1

  # FIXME hardcoded caps
  def_known_sink_pads sink:
                        {:always, {:pull, demand_in: :bytes},
                         {Caps, channels: 2, sample_rate: 48000, format: :s16le}}

  def_options endpoint_id: [
                type: :integer,
                spec: integer | :default,
                default: :default,
                description: "PortAudio sound card id"
              ],
              ringbuffer_size: [
                type: :integer,
                spec: pos_integer,
                default: 4096,
                description: "Size of the ringbuffer (in frames)"
              ],
              portaudio_buffer_size: [
                type: :integer,
                spec: pos_integer,
                default: 256,
                description: "Size of the portaudio buffer (in frames)"
              ],
              latency: [
                type: :atom,
                spec: :low | :high,
                default: :high,
                description: "Latency of the output device"
              ]

  @impl true
  def handle_init(%__MODULE__{} = options) do
    {:ok,
     %{
       endpoint_id: options.endpoint_id,
       ringbuffer_size: options.ringbuffer_size,
       pa_buffer_size: options.portaudio_buffer_size,
       latency: options.latency,
       native: nil,
       playing: false
     }}
  end

  @impl true
  def handle_play(state) do
    %{
      endpoint_id: endpoint_id,
      ringbuffer_size: ringbuffer_size,
      pa_buffer_size: pa_buffer_size,
      latency: latency
    } = state

    state = %{state | playing: true}

    endpoint_id = if endpoint_id == :default, do: @pa_no_device, else: endpoint_id

    with {:ok, native} <-
           @native.create_sink(self(), endpoint_id, ringbuffer_size, pa_buffer_size, latency) do
      {:ok, %{state | native: native}}
    else
      {:error, reason} -> {{:error, reason}, state}
    end
  end

  @impl true
  def handle_prepare(:playing, %{native: native} = state) do
    {@native.destroy_sink(native), %{state | native: nil, playing: false}}
  end

  @impl true
  def handle_prepare(_, state) do
    {:ok, state}
  end

  @impl true
  def handle_other(
        {:membrane_element_portaudio_ringbuffer_demand, size},
        %{playing: true} = state
      ) do
    {{:ok, demand: {:sink, size}}, state}
  end

  @impl true
  def handle_other({:membrane_element_portaudio_ringbuffer_demand, _size}, state) do
    {:ok, state}
  end

  @impl true
  def handle_write1(:sink, %Buffer{payload: payload}, _, %{native: native} = state) do
    {@native.write(native, payload), state}
  end
end
