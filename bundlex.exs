defmodule Membrane.PortAudio.BundlexProject do
  use Bundlex.Project

  def project() do
    [
      natives: natives(Bundlex.platform())
    ]
  end

  defp natives(_platform) do
    [
      sink: [
        interface: :nif,
        deps: [membrane_common_c: [:membrane, :membrane_ringbuffer], unifex: :unifex],
        sources: ["sink.c", "pa_helper.c"],
        pkg_configs: ["portaudio-2.0"],
        preprocessor: Unifex
      ],
      source: [
        interface: :nif,
        deps: [membrane_common_c: :membrane, unifex: :unifex],
        sources: ["source.c", "pa_helper.c"],
        pkg_configs: ["portaudio-2.0"],
        preprocessor: Unifex
      ]
    ]
  end
end
