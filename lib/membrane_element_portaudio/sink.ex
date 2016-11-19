defmodule Membrane.Element.PortAudio.SinkOptions do
  defstruct \
    device_id: nil,
    buffer_size: 256

  @type t :: %Membrane.Element.PortAudio.SinkOptions{
    device_id: String.t | nil,
    buffer_size: non_neg_integer
  }
end


defmodule Membrane.Element.PortAudio.Sink do
  use Membrane.Element.Base.Sink
  alias Membrane.Element.PortAudio.SinkOptions


  # Private API

  @doc false
  def handle_init(%SinkOptions{device_id: device_id, buffer_size: buffer_size}) do
    {:ok, %{
      device_id: device_id,
      buffer_size: buffer_size,
      native: nil,
    }}
  end


  @doc false
  def handle_prepare(%{device_id: device_id, buffer_size: buffer_size} = state) do
    case Membrane.Element.PortAudio.SinkNative.create(device_id, buffer_size) do
      {:ok, native} ->
        {:ok, %{state | native: native}}

      {:error, reason} ->
        {:error, {:create, reason}, state}
    end
  end


  @doc false
  def handle_buffer(%Membrane.Buffer{caps: %Membrane.Caps.Audio.Raw{channels: 2, sample_rate: 48000, format: :s16le}, payload: payload}, %{native: native} = state) do
    case Membrane.Element.PortAudio.SinkNative.write(native, payload) do
      :ok ->
        {:ok, state}

      {:error, reason} ->
        {:error, {:write, reason}, state}
    end
  end
end
