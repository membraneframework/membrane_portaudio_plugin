defmodule Membrane.Element.Portaudio.SourceTest do
  @moduledoc false

  use ExUnit.Case, async: true
  use Mockery
  alias Membrane.Element.PortAudio.{Source, Native}
  alias Membrane.Caps.Audio.Raw, as: Caps

  @module Source

  def state(_ctx) do
    state = %{
      endpoint_id: :default,
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

  describe "soundcard_requiring_tests" do
    @describetag soundcard: true

    test "multiple parallel restarts should not cause errors", %{state: state} do
      1..20
      |> Task.async_stream(
        fn _ ->
          assert {{:ok, [_caps]}, state} = @module.handle_play(state)
          :timer.sleep(10..200 |> Enum.random())
          assert {:ok, _state} = @module.handle_prepare(:playing, state)
        end,
        max_concurrency: 4
      )
      |> Stream.run()
    end

    test "after starting some buffers should be received", %{state: state} do
      assert {{:ok, [_caps]}, state} = @module.handle_play(state)
      assert_receive({:membrane_element_portaudio_source_packet, _payload}, 1000)
      assert {:ok, _state} = @module.handle_prepare(:playing, state)
    end
  end
end
