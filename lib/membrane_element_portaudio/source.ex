defmodule Membrane.Element.PortAudio.Source do
  @moduledoc """
  Audio source that captures sound via multi-platform PortAudio library.
  """

  use Membrane.Element.Base.Source
  alias Membrane.Buffer
  alias __MODULE__.Native
  alias Membrane.Caps.Audio.Raw, as: Caps

  def_known_source_pads source:
                          {:always, :push,
                           {Caps, channels: 2, sample_rate: 48000, format: :s16le}}

  # FIXME: improve endpoint_id option
  def_options endpoint_id: [
                type: :string,
                spec: String.t() | nil,
                default: nil,
                description: "Portaudio sound card id"
              ],
              buffer_size: [
                type: :integer,
                spec: pos_integer,
                default: 256,
                description: "Size of each incoming buffer (in frames)"
              ]

  @impl true
  def handle_init(%__MODULE__{endpoint_id: endpoint_id, buffer_size: buffer_size}) do
    {:ok,
     %{
       endpoint_id: endpoint_id,
       buffer_size: buffer_size,
       native: nil
     }}
  end

  @impl true
  def handle_prepare(:stopped, %{endpoint_id: endpoint_id, buffer_size: buffer_size} = state) do
    with {:ok, native} <- Native.create(endpoint_id, self(), buffer_size) do
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
  def handle_play(%{native: native} = state) do
    {Native.start(native), state}
  end

  @impl true
  def handle_stop(%{native: native} = state) do
    {Native.stop(native), state}
  end

  @impl true
  def handle_other({:membrane_element_portaudio_source_packet, payload}, state) do
    {{:ok, buffer: {:source, %Buffer{payload: payload}}}, state}
  end
end
