defmodule Membrane.Element.PortAudio.Source.Native do
  @moduledoc false

  use Bundlex.Loader, nif: :source

  @spec create(pid, integer, pos_integer, :low | :high) :: {:ok, reference} | {:error, any}
  defnif create(destination, endpoint_id, pa_buffer_size, latency)
end
