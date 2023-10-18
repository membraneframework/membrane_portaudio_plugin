defmodule Membrane.PortAudio.BundlexProject do
  use Bundlex.Project

  def project() do
    [
      natives: natives()
    ]
  end

  defp get_portaudio() do
    url_prefix =
      "https://github.com/membraneframework-precompiled/precompiled_portaudio/releases/latest/download/portaudio"

    case Bundlex.get_target() do
      %{architecture: "x86_64", os: "darwin" <> _rest_of_os_name} ->
        {[{:precompiled, "#{url_prefix}_macos_intel.tar.gz"}, :pkg_config], "portaudio"}

      %{architecture: "aarch64", os: "darwin" <> _rest_of_os_name} ->
        {[:pkg_config], "portaudio-2.0"}

      _other ->
        {[:pkg_config], "portaudio"}
    end
  end

  defp natives() do
    [
      sink: [
        interface: :nif,
        deps: [membrane_common_c: [:membrane, :membrane_ringbuffer], unifex: :unifex],
        sources: ["sink.c", "pa_helper.c"],
        os_deps: [get_portaudio()],
        preprocessor: Unifex
      ],
      source: [
        interface: :nif,
        deps: [membrane_common_c: :membrane, unifex: :unifex],
        sources: ["source.c", "pa_helper.c"],
        os_deps: [get_portaudio()],
        preprocessor: Unifex
      ],
      pa_devices: [
        interface: :nif,
        deps: [unifex: :unifex],
        sources: ["pa_devices.c"],
        os_deps: [get_portaudio()],
        preprocessor: Unifex
      ]
    ]
  end
end
