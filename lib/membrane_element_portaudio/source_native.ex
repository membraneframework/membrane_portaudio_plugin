defmodule Membrane.Element.PortAudio.Source.Native do
  @moduledoc """
  This module is an interface to native PortAudio source.
  """

  use Bundlex.Loader, nif: :source


  @doc """
  Creates PortAudio source.

  Expects X arguments:

  - ... TODO

  On success, returns `{:ok, resource}`.

  On bad arguments passed, returns `{:error, {:args, field, description}}`.

  On source initialization error, returns `{:error, {:create, reason}}`.
  """
  @spec create(String.t | nil, pid, non_neg_integer) ::
    {:ok, any} | {:error, {:args, atom, String.t}} | {:error, {:create, atom}}
  defnif create(endpoint_id, destination, buffer_size)


  @doc """
  Starts PortAudio source.

  Expects 1 argument:

  - handle to the source

  On success, returns `:ok`.

  On bad arguments passed, returns `{:error, {:args, field, description}}`.

  On internal error, returns `{:error, {:internal, reason}}`.
  """
  @spec start(any) ::
    :ok | {:error, {:args, atom, String.t}} | {:error, {:internal, atom}}
  defnif start(handle)


  @doc """
  Stops PortAudio source.

  Expects 1 argument:

  - handle to the source

  On success, returns `:ok`.

  On bad arguments passed, returns `{:error, {:args, field, description}}`.

  On internal error, returns `{:error, {:internal, reason}}`.
  """
  @spec stop(any) ::
    :ok | {:error, {:args, atom, String.t}} | {:error, {:internal, atom}}
  defnif stop(handle)

end
