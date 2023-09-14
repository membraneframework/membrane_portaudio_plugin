defmodule Membrane.PortAudio.BundlexProject do
  use Bundlex.Project

  def project() do
    [
      natives: natives()
    ]
  end

  defp get_portaudio_url() do
    case Bundlex.get_target() do
      %{os: "linux"} ->
        {:precompiled,
         "https://github.com/membraneframework-labs/precompiled_portaudio/releases/download/version1/portaudio_linux.tar.gz"}

      %{architecture: "x86_64", os: "darwin" <> _rest_of_os_name} ->
        {:precompiled,
         "https://github.com/membraneframework-precompiled/precompiled_portaudio/releases/download/version1/portaudio_macos_intel.tar.gz"}

      _other ->
        nil
    end
  end

  defp natives() do
    [
      sink: [
        interface: :nif,
        deps: [membrane_common_c: [:membrane, :membrane_ringbuffer], unifex: :unifex],
        sources: ["sink.c", "pa_helper.c"],
        os_deps: [{get_portaudio_url(), "portaudio"}],
        preprocessor: Unifex
      ],
      source: [
        interface: :nif,
        deps: [membrane_common_c: :membrane, unifex: :unifex],
        sources: ["source.c", "pa_helper.c"],
        os_deps: [{get_portaudio_url(), "portaudio"}],
        preprocessor: Unifex
      ]
    ]
  end
end
