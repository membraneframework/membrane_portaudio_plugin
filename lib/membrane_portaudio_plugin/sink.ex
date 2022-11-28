defmodule Membrane.PortAudio.Sink do
  @moduledoc """
  Audio sink that plays sound via multi-platform PortAudio library.
  """

  use Membrane.Sink

  import Mockery.Macro

  alias __MODULE__.Native
  alias Membrane.Buffer
  alias Membrane.PortAudio.SyncExecutor
  alias Membrane.RawAudio
  alias Membrane.Time

  @pa_no_device -1

  def_clock """
  This clock measures time by counting a number of samples consumed by a PortAudio device
  and allows synchronization with it.
  """

  def_input_pad :input,
    demand_unit: :bytes,
    # TODO Add support for different formats
    accepted_format: %RawAudio{channels: 2, sample_rate: 48_000, sample_format: :s16le}

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
  def handle_init(_ctx, %__MODULE__{} = options) do
    {[],
     options
     |> Map.from_struct()
     |> Map.merge(%{
       native: nil,
       latency_time: 0
     })}
  end

  @impl true
  def handle_playing(ctx, state) do
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
             ctx.clock,
             endpoint_id,
             ringbuffer_size,
             pa_buffer_size,
             latency
           ]) do
      Membrane.ResourceGuard.register(ctx.resource_guard, fn ->
        SyncExecutor.apply(Native, :destroy, native)
      end)

      {[], %{state | latency_time: latency_ms |> Time.milliseconds(), native: native}}
    else
      {:error, reason} -> raise "Error: #{inspect(reason)}"
    end
  end

  @impl true
  def handle_info({:portaudio_demand, size}, %{playback: :playing}, state) do
    {[demand: {:input, &(&1 + size)}], state}
  end

  @impl true
  def handle_info({:portaudio_demand, _size}, _ctx, state) do
    {[], state}
  end

  @impl true
  def handle_write(:input, %Buffer{payload: payload}, _ctx, %{native: native} = state) do
    mockable(Native).write_data(payload, native)
    {[], state}
  end
end
