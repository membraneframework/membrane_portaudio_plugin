defmodule Membrane.PortAudio do
  @moduledoc """
  PortAudio utilities.
  """
  use Application

  @impl true
  def start(_type, _args) do
    children = [__MODULE__.SyncExecutor]

    opts = [strategy: :one_for_one, name: Membrane.PortAudio]
    Supervisor.start_link(children, opts)
  end

  @doc """
  Prints names and ids of available audio devices to stdout.

  Corresponding task `mix pa_devices` is available too.
  """
  @spec print_devices() :: :ok
  def print_devices() do
    Application.ensure_all_started(:membrane_portaudio_plugin)
    __MODULE__.SyncExecutor.apply(__MODULE__.Devices, :list, [])
  end
end
