if Bundlex.get_target().os |> String.starts_with?("darwin") do
  defmodule Membrane.PortAudio.OSXPermissions do
    @moduledoc false

    use Bundlex.Loader, nif: :osx_permissions

    defnif request_mic()
  end
end
