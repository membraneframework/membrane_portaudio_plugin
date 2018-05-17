defmodule Membrane.Element.PortAudio.Sink.Native do
  @moduledoc """
  This module is an interface to native PortAudio sink.
  """

  use Bundlex.Loader, nif: :sink

  @doc """
  Creates PortAudio sink.

  Expects X arguments:

  - ... TODO

  On success, returns `{:ok, resource}`.

  On bad arguments passed, returns `{:error, {:args, field, description}}`.

  On sink initialization error, returns `{:error, {:create, reason}}`.
  """
  @spec create(integer, non_neg_integer, pid, :low | :high) ::
          {:ok, any} | {:error, any}
  defnif create(endpoint_id, buffer_size, demand_handler, latency)

  @doc """
  Writes data to the PortAudio sink.

  Expects 2 arguments:

  - handle to the sink
  - buffer

  On success, returns `:ok`.

  On bad arguments passed, returns `{:error, {:args, field, description}}`.

  On internal error, returns `{:error, {:write, reason}}`.
  """
  @spec write(any, %Membrane.Buffer{}) ::
          :ok | {:error, {:args, atom, String.t()}} | {:error, {:internal, atom}}
  defnif write(handle, buffer)

  @doc """
  Returns PortAudio default output device id
  """
  @spec get_default_endpoint_id() :: integer
  defnif get_default_endpoint_id()
end
