defmodule Membrane.Element.PortAudio.Native do
  @moduledoc """
  Native interface to PortAudio. Sink and source are not split into separate NIFs
  because some PortAudio functions are not thread safe and synchronization
  between calls to them must have been provided.
  """

  use Bundlex.Loader, nif: :native

  @spec create_sink(pid, integer, pos_integer, pos_integer, :low | :high) ::
          {:ok, reference} | {:error, any}
  defnif create_sink(demand_handler, endpoint_id, ringbuffer_size, pa_buffer_size, latency)

  @spec write(reference, binary) :: :ok | {:error, any}
  defnif write(handle, buffer)

  @spec destroy_sink(reference) :: :ok
  defnif destroy_sink(handle)

  @spec create_source(pid, integer, pos_integer, :low | :high) :: {:ok, reference} | {:error, any}
  defnif create_source(destination, endpoint_id, pa_buffer_size, latency)

  @spec destroy_source(reference) :: :ok
  defnif destroy_source(handle)
end
