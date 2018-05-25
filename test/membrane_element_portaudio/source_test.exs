defmodule Membrane.Element.Portaudio.SourceTest do
  @moduledoc false

  use ExUnit.Case, async: true
  use Mockery
  alias Membrane.Element.PortAudio.{Source, Native}
  alias Membrane.Caps.Audio.Raw, as: Caps

  @module Source

  def state(_ctx) do
    state = %{
      endpoint_id: 10,
      pa_buffer_size: 256,
      latency: :high,
      native: nil,
      playing: false
    }

    %{state: state}
  end

  def playing(%{state: state}) do
    %{state: %{state | native: make_ref(), playing: true}}
  end

  setup_all :state

  describe "handle_play" do
    test "should start portaudio and send caps", %{state: state} do
      ref = make_ref()
      mock(Native, [create_source: 4], {:ok, ref})

      assert {{:ok, caps: {:source, %Caps{channels: 2, sample_rate: 48000, format: :s16le}}},
              %{state | native: ref, playing: true}} == @module.handle_play(state)
    end
  end

  describe "handle_prepare_playing" do
    setup :playing

    test "should close portaudio", %{state: state} do
      mock(Native, [destroy_source: 1], :ok)

      assert {:ok, %{state | native: nil, playing: false}} ==
               @module.handle_prepare(:playing, state)

      %{native: native} = state
      assert_called(Native, :destroy_source, [^native])
    end
  end
end
