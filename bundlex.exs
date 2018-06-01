defmodule Membrane.Element.PortAudio.BundlexProject do
  use Bundlex.Project

  def project() do
    [
      nifs: nifs(Bundlex.platform())
    ]
  end

  defp nifs(_platform) do
    [
      native: [
        deps: [membrane_common_c: [:membrane, :membrane_ringbuffer]],
        sources: ["native.c", "sink.c", "source.c", "pa_helper.c"],
        pkg_configs: ["portaudio-2.0"]
      ]
    ]
  end
end
