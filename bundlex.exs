defmodule Membrane.PortAudio.BundlexProject do
  use Bundlex.Project

  def project() do
    [
      natives: natives()
    ]
  end

  defp get_portaudio_url() do
    url_prefix =
      "https://github.com/membraneframework-precompiled/precompiled_portaudio/releases/latest/download/portaudio"

    case Bundlex.get_target() do
      %{os: "linux"} ->
        {:precompiled, "#{url_prefix}_linux.tar.gz"}

      %{architecture: "x86_64", os: "darwin" <> _rest_of_os_name} ->
        {:precompiled, "#{url_prefix}_macos_intel.tar.gz"}

      %{architecture: "aarch64", os: "darwin" <> _rest_of_os_name} ->
        {:precompiled, "#{url_prefix}_macos_arm.tar.gz"}

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
        os_deps: [{[get_portaudio_url(), :pkg_config], "portaudio"}],
        preprocessor: Unifex
      ],
      source: [
        interface: :nif,
        deps: [membrane_common_c: :membrane, unifex: :unifex],
        sources: ["source.c", "pa_helper.c"],
        os_deps: [{[get_portaudio_url(), :pkg_config], "portaudio"}],
        preprocessor: Unifex
      ]
    ]
  end
end
