defmodule Membrane.Element.Portaudio.SinkTest do
  @moduledoc false

  use ExUnit.Case, async: true
  use Mockery
  alias Membrane.Element.PortAudio.Sink
  alias Sink.Native
  alias Membrane.Buffer

  @module Sink

  def state(_ctx) do
    {:ok, state} =
      @module.handle_init(%Sink{
        endpoint_id: :default,
        ringbuffer_size: 4096,
        portaudio_buffer_size: 256,
        latency: :high
      })

    {:ok, clock} = Membrane.Clock.start_link()
    ctx = %{clock: clock}

    %{ctx: ctx, state: state}
  end

  def playing(%{state: state}) do
    %{state: %{state | native: make_ref()}}
  end

  setup_all :state

  describe "handle_prepared_to_playing" do
    @tag skip: "Temporairly disabled due to mocking issues"
    test "should start portaudio", %{state: state} do
      ref = make_ref()
      mock(Native, [create: 5], {:ok, ref})
      assert {:ok, %{state | native: ref}} == @module.handle_prepared_to_playing(nil, state)
    end
  end

  describe "handle_write" do
    setup :playing

    test "should call portaudio", %{state: state} do
      mock(Native, [write_data: 2], :ok)
      payload = <<1, 2, 3, 4>>
      assert {:ok, state} == @module.handle_write(:input, %Buffer{payload: payload}, nil, state)
      %{native: native} = state
      assert_called(Native, :write_data, [^payload, ^native])
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

  describe "Using soundcard," do
    @describetag soundcard: true

    test "multiple parallel restarts should not cause errors", %{ctx: ctx, state: state} do
      1..20
      |> Task.async_stream(
        fn _ ->
          assert {:ok, state} = @module.handle_prepared_to_playing(ctx, state)
          :timer.sleep(10..200 |> Enum.random())
          assert {:ok, _state} = @module.handle_playing_to_prepared(ctx, state)
        end,
        max_concurrency: 4
      )
      |> Stream.run()
    end

    test "after starting, the initial demand of the size of the ringbuffer should be received", %{
      ctx: ctx,
      state: state
    } do
      assert {:ok, state} = @module.handle_prepared_to_playing(ctx, state)
      assert_receive({:portaudio_demand, initial_demand_size}, 1000)
      assert initial_demand_size == 4 * state.ringbuffer_size
      assert {:ok, _state} = @module.handle_playing_to_prepared(ctx, state)
    end
  end
end
