defmodule Membrane.PortAudio.Source do
  @moduledoc """
  Audio source that captures sound via multi-platform PortAudio library.
  """

  use Membrane.Source

  alias Membrane.Buffer
  alias Membrane.RawAudio
  alias Membrane.PortAudio.SyncExecutor
  alias __MODULE__.Native

  @pa_no_device -1

  # TODO Add support for different formats
  def_output_pad :output,
    mode: :push,
    caps: {RawAudio, channels: 2, sample_rate: 48_000, sample_format: :s16le}

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
      portaudio_buffer_size: pa_buffer_size,
      latency: latency
    } = state

    endpoint_id = if endpoint_id == :default, do: @pa_no_device, else: endpoint_id

    with {:ok, native} <-
           SyncExecutor.apply(Native, :create, [self(), endpoint_id, pa_buffer_size, latency]) do
      # TODO Add support for different formats
      {{:ok, caps: {:output, %RawAudio{channels: 2, sample_rate: 48_000, sample_format: :s16le}}},
       %{state | native: native}}
    else
      {:error, reason} -> {{:error, reason}, state}
    end
  end

  @impl true
  def handle_playing_to_prepared(_ctx, %{native: native} = state) do
    {SyncExecutor.apply(Native, :destroy, native), %{state | native: nil}}
  end

  @impl true
  def handle_other({:portaudio_payload, payload}, %{playback_state: :playing}, state) do
    {{:ok, buffer: {:output, %Buffer{payload: payload}}}, state}
  end

  @impl true
  def handle_other({:portaudio_payload, _payload}, _ctx, state) do
    {:ok, state}
  end
end
