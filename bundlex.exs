defmodule MyApp.BundlexProject do
  use Bundlex.Project

  def project() do
    [
      nifs: nifs(Bundlex.platform())
    ]
  end

  defp nifs(_platform) do
    [
      sink: [
        deps: [membrane_common_c: [:membrane]],
        sources: ["sink.c", "pa_ringbuffer.c"],
        pkg_configs: ["portaudio-2.0"]
      ],
      source: [
        deps: [membrane_common_c: [:membrane]],
        sources: ["source.c"],
        pkg_configs: ["portaudio-2.0"]
      ]
    ]
  end
end