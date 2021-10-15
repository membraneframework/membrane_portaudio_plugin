defmodule Membrane.PortAudio.SyncExecutor do
  @moduledoc """
  A GenServer executing actions received by `GenServer.call/3` or `send/2`.

  Some PortAudio operations (such as starting and stopping stream) must not be
  executed concurrently, so they are received and executed here, synchronously.
  """
  import Mockery.Macro
  use GenServer

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  @doc """
  A simple wrapper around `GenServer.call/3.`
  """
  @spec apply(module, atom, list | any, timeout()) :: term
  def apply(module, fun_name, args, timeout \\ 5000) do
    GenServer.call(__MODULE__, {module, fun_name, args}, timeout)
  end

  @impl GenServer
  def init(_args) do
    {:ok, %{}}
  end

  @impl GenServer
  def handle_call(executable, _from, state) do
    {:reply, handle_apply(executable), state}
  end

  @impl GenServer
  def handle_info(executable, state) do
    handle_apply(executable)
    {:noreply, state}
  end

  defp handle_apply({module, fun_name, args}) when is_atom(module) and is_atom(fun_name) do
    Kernel.apply(mockable(module), fun_name, args |> Bunch.listify())
  end
end
