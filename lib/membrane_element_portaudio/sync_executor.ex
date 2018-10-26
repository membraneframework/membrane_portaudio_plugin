defmodule Membrane.Element.PortAudio.SyncExecutor do
  @moduledoc """
  A GenServer executing actions received by `GenServer.call/3` or `send/2`.

  Some PortAudio operations (such as starting and stopping stream) must not be
  executed concurrently, so they are received and executed here, synchronously.
  """
  use GenServer

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  @impl GenServer
  def init(_args) do
    {:ok, %{}}
  end

  @impl GenServer
  def handle_call(executable, _from, state) do
    {:reply, exec(executable), state}
  end

  @impl GenServer
  def handle_info(executable, state) do
    exec(executable)
    {:noreply, state}
  end

  defp exec({module, fun_name, args}) when is_atom(module) and is_atom(fun_name) do
    apply(module, fun_name, args |> Bunch.listify())
  end
end
