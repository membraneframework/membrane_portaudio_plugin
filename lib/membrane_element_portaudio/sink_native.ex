defmodule Membrane.Element.PortAudio.Sink.Native do
  @moduledoc false

  use Bundlex.Loader, nif: :sink

  @spec create(pid, integer, pos_integer, pos_integer, :low | :high) :: {:ok, any} | {:error, any}
  defnif create(demand_handler, endpoint_id, ringbuffer_size, pa_buffer_size, latency)

  @spec write(any, %Membrane.Buffer{}) ::
          :ok | {:error, {:args, atom, String.t()}} | {:error, {:internal, atom}}
  defnif write(handle, buffer)

  @spec get_default_endpoint_id() :: integer
  defnif get_default_endpoint_id()
end
