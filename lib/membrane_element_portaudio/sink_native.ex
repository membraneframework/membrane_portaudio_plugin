defmodule Membrane.Element.PortAudio.Sink.Native do
  @moduledoc false

  use Bundlex.Loader, nif: :sink

  @spec create(pid, integer, pos_integer, pos_integer, :low | :high) ::
          {:ok, reference} | {:error, any}
  defnif create(demand_handler, endpoint_id, ringbuffer_size, pa_buffer_size, latency)

  @spec write(reference, binary) :: :ok | {:error, any}
  defnif write(handle, buffer)
end
