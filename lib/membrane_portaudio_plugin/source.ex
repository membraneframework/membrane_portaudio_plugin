defmodule Membrane.PortAudio.Source do
  @moduledoc """
  Audio source that captures sound via multi-platform PortAudio library.
  """

  use Membrane.Source

  require Membrane.Logger

  alias __MODULE__.Native
  alias Membrane.Buffer
  alias Membrane.PortAudio.{OSXPermissions, SyncExecutor}
  alias Membrane.RawAudio

  @sample_formats [:u8le, :s8le, :s16le, :s24le, :s32le, :f32le]
  @type sample_format :: unquote(Bunch.Typespec.enum_to_alternative(@sample_formats))

  @pa_no_device -1

  # TODO Add support for different formats
  def_output_pad :output,
    flow_control: :push,
    accepted_format: %RawAudio{sample_format: format} when format in @sample_formats

  def_options device_id: [
                spec: integer() | :default,
                default: :default,
                description: """
                PortAudio device id. Defaults to the default input device.

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
              portaudio_buffer_size: [
                spec: pos_integer(),
                default: 256,
                description: "Size of the PortAudio buffer (in frames)"
              ],
              latency: [
                spec: :low | :high,
                default: :high,
                description: "Latency of the input device"
              ],
              sample_format: [
                spec: sample_format(),
                default: :s16le,
                description: """
                Sample format to output.
                """
              ],
              sample_rate: [
                spec: non_neg_integer(),
                default: nil,
                description: """
                Sample rate to output.

                If not set, device's default sample rate will be used.
                """
              ],
              channels: [
                spec: 1..2,
                default: nil,
                description: """
                Number of channels to output.

                If not set, device's default will be used.
                """
              ]

  @impl true
  def handle_init(ctx, %__MODULE__{endpoint_id: endpoint_id} = options)
      when endpoint_id != nil do
    Membrane.Logger.warning("endpoint_id option has been renamed to device_id")
    handle_init(ctx, Map.delete(options, :endpoint_id))
  end

  @impl true
  def handle_init(_ctx, %__MODULE__{} = options) do
    if Code.ensure_loaded?(OSXPermissions), do: apply(OSXPermissions, :request_mic, [])

    {[],
     options
     |> Map.from_struct()
     |> Map.merge(%{
       native: nil
     })}
  end

  @impl true
  def handle_playing(ctx, state) do
    %{
      device_id: device_id,
      portaudio_buffer_size: pa_buffer_size,
      latency: latency,
      sample_format: sample_format,
      channels: channels,
      sample_rate: sample_rate,
      init_time: nil
    } = state

    device_id = if device_id == :default, do: @pa_no_device, else: device_id

    with {:ok, native, channels, sample_rate} <-
           SyncExecutor.apply(Native, :create, [
             self(),
             device_id,
             pa_buffer_size,
             latency,
             sample_format,
             channels || 0,
             sample_rate || -1
           ]) do
      Membrane.ResourceGuard.register(
        ctx.resource_guard,
        fn -> SyncExecutor.apply(Native, :destroy, native) end
      )

      {[
         stream_format:
           {:output,
            %RawAudio{channels: channels, sample_rate: sample_rate, sample_format: sample_format}}
       ], %{state | native: native}}
    else
      {:error, reason} -> raise "Error: #{inspect(reason)}"
    end
  end

  @impl true
  def handle_info({:portaudio_payload, payload}, %{playback: :playing}, state) do
    time = Membrane.Time.monotonic_time()
    init_time = state.init_time || time
    buffer = %Buffer{payload: payload, pts: time - init_time}

    {[buffer: {:output, buffer}], %{state | init_time: init_time}}
  end

  @impl true
  def handle_info({:portaudio_payload, _payload}, _ctx, state) do
    {[], state}
  end
end
