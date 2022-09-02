defmodule Membrane.Portaudio.SourceTest do
  @moduledoc false

  use ExUnit.Case, async: true
  use Mockery

  alias Membrane.PortAudio.{Native, Source}
  alias Membrane.RawAudio

  @module Source

  defp state(_ctx) do
    state = %{
      endpoint_id: :default,
      portaudio_buffer_size: 256,
      latency: :high,
      native: nil
    }

    %{state: state}
  end

  defp playing(%{state: state}) do
    %{state: %{state | native: make_ref(), playing: true}}
  end

  setup_all :state

  describe "handle_prepared_to_playing" do
    @tag skip: "Temporairly disabled due to mocking issues"
    test "should start portaudio and send caps", %{state: state} do
      ref = make_ref()
      mock(Native, [create: 4], {:ok, ref})

      assert {{:ok,
               caps: {:source, %RawAudio{channels: 2, sample_rate: 48_000, sample_format: :s16le}}},
              %{state | native: ref}} == @module.handle_prepared_to_playing(nil, state)
    end
  end

  describe "handle_playing_to_prepared" do
    setup :playing

    @tag skip: "Temporairly disabled due to mocking issues"
    test "should close portaudio", %{state: state} do
      mock(Native, [destroy: 1], :ok)

      assert {:ok, %{state | native: nil}} == @module.handle_playing_to_prepared(nil, state)

      %{native: native} = state
      assert_called(Native, :destroy, [^native])
    end
  end

  describe "soundcard_requiring_tests" do
    @describetag soundcard: true

    test "multiple parallel restarts should not cause errors", %{state: state} do
      1..20
      |> Task.async_stream(
        fn _i ->
          assert {{:ok, [_actions]}, state} = @module.handle_prepared_to_playing(nil, state)
          :timer.sleep(10..200 |> Enum.random())
          assert {:ok, _state} = @module.handle_playing_to_prepared(nil, state)
        end,
        max_concurrency: 4
      )
      |> Stream.run()
    end

    test "after starting some buffers should be received", %{state: state} do
      assert {{:ok, [_actions]}, state} = @module.handle_prepared_to_playing(nil, state)
      assert_receive({:portaudio_payload, _payload}, 1000)
      assert {:ok, _state} = @module.handle_playing_to_prepared(nil, state)
    end
  end
end
