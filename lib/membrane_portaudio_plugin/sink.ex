defmodule Membrane.PortAudio.Sink do
  @moduledoc """
  Audio sink that plays sound via multi-platform PortAudio library.
  """

  use Membrane.Sink

  import Mockery.Macro

  require Membrane.Logger

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
    flow_control: :manual,
    accepted_format:
      %RawAudio{sample_format: format} when format in [:f32le, :s32le, :s24le, :s16le, :s8, :u8]

  def_options device_id: [
                type: :integer,
                spec: integer | :default,
                default: :default,
                description: """
                PortAudio device id. Defaults to the default output device.

                You can list available devices with `mix pa_devices` or
                `Membrane.PortAudio.print_devices/0`.
                """
              ],
              endpoint_id: [
                type: nil,
                spec: nil,
                default: nil,
                description: """
                Deprecated. Please use device_id instead.
                """
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
  def handle_init(ctx, %__MODULE__{endpoint_id: endpoint_id} = options)
      when endpoint_id != nil do
    Membrane.Logger.warning("endpoint_id option has been renamed to device_id")
    handle_init(ctx, Map.delete(options, :endpoint_id))
  end

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
  def handle_stream_format(:input, %Membrane.RawAudio{} = format, ctx, state) do
    %{
      device_id: device_id,
      ringbuffer_size: ringbuffer_size,
      portaudio_buffer_size: pa_buffer_size,
      latency: latency
    } = state

    device_id = if device_id == :default, do: @pa_no_device, else: device_id

    with {:ok, {latency_ms, native}} <-
           SyncExecutor.apply(Native, :create, [
             self(),
             ctx.clock,
             device_id,
             format.sample_rate,
             format.channels,
             format.sample_format,
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
  def handle_buffer(:input, %Buffer{payload: payload}, _ctx, %{native: native} = state) do
    mockable(Native).write_data(payload, native)
    {[], state}
  end
end
