defmodule Membrane.Element.PortAudio.Sink do
  @moduledoc """
  Audio sink that plays sound via multi-platform PortAudio library.
  """

  alias Membrane.Buffer
  alias Membrane.Caps.Audio.Raw, as: Caps
  alias Membrane.Element.PortAudio.SyncExecutor
  alias Membrane.Event.StartOfStream
  alias Membrane.Sync
  alias Membrane.Time
  alias __MODULE__.Native
  import Mockery.Macro
  use Membrane.Element.Base.Sink

  @pa_no_device -1

  # FIXME hardcoded caps
  def_input_pad :input,
    demand_unit: :bytes,
    caps: {Caps, channels: 2, sample_rate: 48_000, format: :s16le}

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
              ],
              sync: [],
              clock: []

  @impl true
  def handle_init(%__MODULE__{} = options) do
    :ok = Sync.register(options.sync)

    {:ok,
     options
     |> Map.from_struct()
     |> Map.merge(%{
       native: nil
     })}
  end

  @impl true
  def handle_event(:input, %StartOfStream{}, _ctx, state) do
    {{:ok, sync: state.sync}, state}
  end

  @impl true
  def handle_event(pad, event, ctx, state) do
    super(pad, event, ctx, state)
  end

  @impl true
  def handle_playing_to_prepared(_ctx, %{native: nil} = state) do
    {:ok, state}
  end

  @impl true
  def handle_playing_to_prepared(_ctx, %{native: native} = state) do
    {SyncExecutor.apply(Native, :destroy, native), %{state | native: nil}}
  end

  @impl true
  def handle_other({:portaudio_demand, size}, %{playback_state: :playing}, state) do
    {{:ok, demand: {:input, &(&1 + size)}}, state}
  end

  @impl true
  def handle_other({:portaudio_demand, _size}, _ctx, state) do
    {:ok, state}
  end

  def handle_sync(sync, ctx, %{sync: sync} = state) do
    IO.inspect(:portaudio_sync)

    %{
      endpoint_id: endpoint_id,
      ringbuffer_size: ringbuffer_size,
      portaudio_buffer_size: pa_buffer_size,
      latency: latency
    } = state

    endpoint_id = if endpoint_id == :default, do: @pa_no_device, else: endpoint_id

    with {:ok, {latency_ms, native}} <-
           SyncExecutor.apply(Native, :create, [
             self(),
             state.clock,
             endpoint_id,
             ringbuffer_size,
             pa_buffer_size,
             latency
           ]) do
      delay =
        Time.milliseconds(latency_ms) +
          Caps.frames_to_time((1.5 * pa_buffer_size) |> trunc, ctx.pads.input.caps)

      {{:ok, sync_delay: delay}, %{state | native: native}}
    else
      {:error, reason} -> {{:error, reason}, state}
    end
  end

  def handle_synced(_sync, _ctx, state) do
    {:ok, state}
  end

  @impl true
  def handle_write(:input, %Buffer{payload: payload}, _ctx, %{native: native} = state) do
    {mockable(Native).write_data(payload, native), state}
  end
end
