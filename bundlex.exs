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
        [{:precompiled, "#{url_prefix}_macos_intel.tar.gz"}, {:pkg_config, "portaudio-2.0"}]

      %{architecture: "aarch64", os: "darwin" <> _rest_of_os_name} ->
        [{:precompiled, "#{url_prefix}_macos_arm.tar.gz"}, {:pkg_config, "portaudio-2.0"}]

      _other ->
        [:pkg_config]
    end
  end

  defp natives() do
    [
      sink: [
        interface: :nif,
        deps: [membrane_common_c: [:membrane, :membrane_ringbuffer]],
        sources: ["sink.c", "pa_helper.c"],
        os_deps: [portaudio: get_portaudio()],
        preprocessor: Unifex
      ],
      source: [
        interface: :nif,
        deps: [membrane_common_c: :membrane],
        sources: ["source.c", "pa_helper.c"],
        os_deps: [portaudio: get_portaudio()],
        preprocessor: Unifex
      ],
      pa_devices: [
        interface: :nif,
        sources: ["pa_devices.c"],
        os_deps: [portaudio: get_portaudio()],
        preprocessor: Unifex
      ]
    ] ++ os_specific(Bundlex.get_target())
  end

  defp os_specific(%{os: "darwin" <> _rest}) do
    [
      osx_permissions: [
        interface: :nif,
        sources: ["osx_permissions.m"],
        libs: ["objc"],
        linker_flags: ["-framework AVFoundation"]
      ]
    ]
  end

  defp os_specific(_target), do: []
end
