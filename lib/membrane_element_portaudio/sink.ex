defmodule Membrane.Element.PortAudio.Sink do
  @moduledoc """
  Audio sink that plays sound via multi-platform PortAudio library.
  """

  alias Membrane.Buffer
  alias Membrane.Caps.Audio.Raw, as: Caps
  alias Membrane.Element.PortAudio.SyncExecutor
  alias __MODULE__.Native
  import Mockery.Macro
  use Membrane.Element.Base.Sink

  @pa_no_device -1

  # FIXME hardcoded caps
  def_input_pads input: [
                   demand_unit: :bytes,
                   caps: {Caps, channels: 2, sample_rate: 48_000, format: :s16le}
                 ]

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
     options
     |> Map.from_struct()
     |> Map.merge(%{
       native: nil
     })}
  end

  @impl true
  def handle_prepared_to_playing(_ctx, state) do
    %{
      endpoint_id: endpoint_id,
      ringbuffer_size: ringbuffer_size,
      portaudio_buffer_size: pa_buffer_size,
      latency: latency
    } = state

    endpoint_id = if endpoint_id == :default, do: @pa_no_device, else: endpoint_id

    with {:ok, native} <-
           SyncExecutor
           |> GenServer.call(
             {Native, :create,
              [
                self(),
                endpoint_id,
                ringbuffer_size,
                pa_buffer_size,
                latency
              ]}
           ) do
      {:ok, %{state | native: native}}
    else
      {:error, reason} -> {{:error, reason}, state}
    end
  end

  @impl true
  def handle_playing_to_prepared(_ctx, %{native: native} = state) do
    {SyncExecutor |> GenServer.call({Native, :destroy, native}), %{state | native: nil}}
  end

  @impl true
  def handle_other({:demand, size}, %{playback_state: :playing}, state) do
    {{:ok, demand: {:input, &(&1 + size)}}, state}
  end

  @impl true
  def handle_other({:demand, _size}, _ctx, state) do
    {:ok, state}
  end

  @impl true
  def handle_write(:input, %Buffer{payload: payload}, _ctx, %{native: native} = state) do
    {mockable(Native).write_data(payload, native), state}
  end
end
