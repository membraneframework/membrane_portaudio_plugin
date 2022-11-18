defmodule Membrane.Portaudio.SourceTest do
  @moduledoc false

  use ExUnit.Case, async: true
  use Mockery

  import Membrane.Testing.Assertions

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

  setup_all :state

  describe "handle_playing" do
    @tag skip: "Temporairly disabled due to mocking issues"
    test "should start portaudio and send stream format", %{state: state} do
      ref = make_ref()
      mock(Native, [create: 4], {:ok, ref})
      {:ok, resource_guard} = Membrane.Testing.MockResourceGuard.start_link()

      assert {[
                stream_format:
                  {:source, %RawAudio{channels: 2, sample_rate: 48_000, sample_format: :s16le}}
              ],
              %{state | native: ref}} ==
               @module.handle_playing(%{resource_guard: resource_guard}, state)

      assert_resource_guard_register(resource_guard, function, _tag)
      function.()
      assert_called(Native, :destroy, [^ref])
    end
  end

  describe "soundcard_requiring_tests" do
    @describetag soundcard: true

    test "multiple parallel restarts should not cause errors", %{state: state} do
      1..20
      |> Task.async_stream(
        fn _i ->
          {:ok, resource_guard} = Membrane.Testing.MockResourceGuard.start_link()

          assert {{:ok, [_actions]}, _state} =
                   @module.handle_playing(%{resource_guard: resource_guard}, state)

          :timer.sleep(10..200 |> Enum.random())
          assert_resource_guard_register(resource_guard, _function, tag)
          Membrane.ResourceGuard.cleanup(resource_guard, tag)
        end,
        max_concurrency: 4
      )
      |> Stream.run()
    end

    test "after starting some buffers should be received", %{state: state} do
      {:ok, resource_guard} = Membrane.Testing.MockResourceGuard.start_link()

      assert {{:ok, [_actions]}, _state} =
               @module.handle_playing(%{resource_guard: resource_guard}, state)

      assert_receive({:portaudio_payload, _payload}, 1000)
    end
  end
end
