defmodule Membrane.Element.PortAudio.SinkNative do
  @moduledoc """
  This module is an interface to native PortAudio sink.
  """

  require Bundlex.Loader


  @on_load :load_nifs

  @doc false
  def load_nifs do
    Bundlex.Loader.load_lib_nif!(:membrane_element_portaudio, :membrane_element_portaudio_sink)
  end


  @doc """
  Creates PortAudio sink.

  Expects X arguments:

  - ... TODO

  On success, returns `{:ok, resource}`.

  On bad arguments passed, returns `{:error, {:args, field, description}}`.

  On sink initialization error, returns `{:error, {:create, reason}}`.
  """
  @spec create(String.t | nil, non_neg_integer) ::
    {:ok, any} | {:error, {:args, atom, String.t}} | {:error, {:create, atom}}
  def create(_endpoint_id, _buffer_size), do: raise "NIF fail"


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
    :ok | {:error, {:args, atom, String.t}} | {:error, {:internal, atom}}
  def write(_handle, _buffer), do: raise "NIF fail"
end
