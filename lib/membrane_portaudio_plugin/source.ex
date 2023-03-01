defmodule Membrane.PortAudio.Source do
  @moduledoc """
  Audio source that captures sound via multi-platform PortAudio library.
  """

  use Membrane.Source

  alias __MODULE__.Native
  alias Membrane.Buffer
  alias Membrane.PortAudio.SyncExecutor
  alias Membrane.RawAudio

  @pa_no_device -1

  # TODO Add support for different formats
  def_output_pad :output,
    mode: :push,
    accepted_format: %RawAudio{channels: 2, sample_rate: 48_000, sample_format: :s16le}

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
  def handle_init(_ctx, %__MODULE__{} = options) do
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
      endpoint_id: endpoint_id,
      portaudio_buffer_size: pa_buffer_size,
      latency: latency
    } = state

    endpoint_id = if endpoint_id == :default, do: @pa_no_device, else: endpoint_id

    with {:ok, native} <-
           SyncExecutor.apply(Native, :create, [self(), endpoint_id, pa_buffer_size, latency]) do
      Membrane.ResourceGuard.register(
        ctx.resource_guard,
        fn -> SyncExecutor.apply(Native, :destroy, native) end
      )

      # TODO Add support for different formats
      {[
         stream_format:
           {:output, %RawAudio{channels: 2, sample_rate: 48_000, sample_format: :s16le}}
       ], %{state | native: native}}
    else
      {:error, reason} -> raise "Error: #{inspect(reason)}"
    end
  end

  @impl true
  def handle_info({:portaudio_payload, payload}, %{playback: :playing}, state) do
    {[buffer: {:output, %Buffer{payload: payload}}], state}
  end

  @impl true
  def handle_info({:portaudio_payload, _payload}, _ctx, state) do
    {[], state}
  end
end
