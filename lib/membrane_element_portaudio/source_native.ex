defmodule Membrane.Element.PortAudio.SourceNative do
  @moduledoc """
  This module is an interface to native PortAudio source.
  """

  require Bundlex.Loader


  @on_load :load_nifs

  @doc false
  def load_nifs do
    Bundlex.Loader.load_lib_nif!(:membrane_element_portaudio, :membrane_element_portaudio_source)
  end


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
  def create(_endpoint_id, _destination, _buffer_size), do: raise "NIF fail"


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
  def start(_handle), do: raise "NIF fail"


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
  def stop(_handle), do: raise "NIF fail"

end
