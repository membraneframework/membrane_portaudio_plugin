defmodule Membrane.Element.Portaudio.SinkTest do
  @moduledoc false

  use ExUnit.Case, async: true
  use Mockery
  alias Membrane.Element.PortAudio.{Sink, Native}
  alias Membrane.Buffer

  @module Sink

  def state(_ctx) do
    state = %{
      endpoint_id: :default,
      ringbuffer_size: 4096,
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
    test "should start portaudio", %{state: state} do
      ref = make_ref()
      mock(Native, [create_sink: 5], {:ok, ref})
      assert {:ok, %{state | native: ref, playing: true}} == @module.handle_play(state)
    end
  end

  describe "handle_write1" do
    setup :playing

    test "should close portaudio", %{state: state} do
      mock(Native, [write: 2], :ok)
      payload = <<1, 2, 3, 4>>
      assert {:ok, state} == @module.handle_write1(:sink, %Buffer{payload: payload}, nil, state)
      %{native: native} = state
      assert_called(Native, :write, [^native, ^payload])
    end
  end

  describe "handle_prepare_playing" do
    setup :playing

    test "should close portaudio", %{state: state} do
      mock(Native, [destroy_sink: 1], :ok)

      assert {:ok, %{state | native: nil, playing: false}} ==
               @module.handle_prepare(:playing, state)

      %{native: native} = state
      assert_called(Native, :destroy_sink, [^native])
    end
  end

  describe "soundcard_requiring_tests" do
    @describetag soundcard: true

    test "multiple parallel restarts should not cause errors", %{state: state} do
      1..20
      |> Task.async_stream(
        fn _ ->
          assert {:ok, state} = @module.handle_play(state)
          :timer.sleep(10..200 |> Enum.random())
          assert {:ok, _state} = @module.handle_prepare(:playing, state)
        end,
        max_concurrency: 4
      )
      |> Stream.run()
    end

    test "after starting initial demand of size of ringbuffer should be received", %{state: state} do
      assert {:ok, state} = @module.handle_play(state)
      assert_receive({:membrane_element_portaudio_ringbuffer_demand, initial_demand_size}, 1000)
      assert initial_demand_size == 4 * state.ringbuffer_size
      assert {:ok, _state} = @module.handle_prepare(:playing, state)
    end
  end
end
