defmodule Membrane.Element.PortAudio.Source do
  @moduledoc """
  Audio source that captures sound via multi-platform PortAudio library.
  """

  use Membrane.Element.Base.Source
  alias Membrane.Buffer
  alias __MODULE__.Native
  alias Membrane.Caps.Audio.Raw, as: Caps

  @pa_no_device -1

  # FIXME hardcoded caps
  def_known_source_pads source:
                          {:always, :push,
                           {Caps, channels: 2, sample_rate: 48000, format: :s16le}}

  def_options endpoint_id: [
                type: :integer,
                spec: integer | :default,
                default: :default,
                description: "PortAudio sound card id"
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
       pa_buffer_size: options.portaudio_buffer_size,
       latency: options.latency,
       native: nil
     }}
  end

  @impl true
  def handle_play(state) do
    %{
      endpoint_id: endpoint_id,
      pa_buffer_size: pa_buffer_size,
      latency: latency
    } = state

    endpoint_id = if endpoint_id == :default, do: @pa_no_device, else: endpoint_id

    with {:ok, native} <- Native.create(self(), endpoint_id, pa_buffer_size, latency) do
      # FIXME hardcoded caps
      {{:ok, caps: {:source, %Caps{channels: 2, sample_rate: 48000, format: :s16le}}},
       %{state | native: native}}
    else
      {:error, reason} -> {{:error, reason}, state}
    end
  end

  @impl true
  def handle_prepare(:playing, state) do
    {:ok, %{state | native: nil}}
  end

  @impl true
  def handle_prepare(_, state) do
    {:ok, state}
  end

  @impl true
  def handle_other({:membrane_element_portaudio_source_packet, payload}, state) do
    {{:ok, buffer: {:source, %Buffer{payload: payload}}}, state}
  end
end
