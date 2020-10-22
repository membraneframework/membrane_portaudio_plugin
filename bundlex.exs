defmodule Membrane.PortAudio.BundlexProject do
  use Bundlex.Project

  def project() do
    [
      nifs: nifs(Bundlex.platform())
    ]
  end

  defp nifs(_platform) do
    [
      sink: [
        deps: [membrane_common_c: [:membrane, :membrane_ringbuffer], unifex: :unifex],
        sources: ["_generated/sink.c", "sink.c", "pa_helper.c"],
        pkg_configs: ["portaudio-2.0"]
      ],
      source: [
        deps: [membrane_common_c: :membrane, unifex: :unifex],
        sources: ["_generated/source.c", "source.c", "pa_helper.c"],
        pkg_configs: ["portaudio-2.0"]
      ]
    ]
  end
end
