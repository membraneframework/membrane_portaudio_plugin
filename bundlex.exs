defmodule Membrane.PortAudio.BundlexProject do
  use Bundlex.Project

  def project() do
    [
      natives: natives()
    ]
  end

  defp natives() do
    [
      sink: [
        interface: :nif,
        deps: [membrane_common_c: [:membrane, :membrane_ringbuffer]],
        sources: ["sink.c", "pa_helper.c"],
        os_deps: [
          portaudio: [
            {:precompiled, Membrane.PrecompiledDependencyProvider.get_dependency_url(:portaudio)},
            {:pkg_config, "portaudio-2.0"}
          ]
        ],
        preprocessor: Unifex
      ],
      source: [
        interface: :nif,
        deps: [membrane_common_c: :membrane],
        sources: ["source.c", "pa_helper.c"],
        os_deps: [
          portaudio: [
            {:precompiled, Membrane.PrecompiledDependencyProvider.get_dependency_url(:portaudio)},
            {:pkg_config, "portaudio-2.0"}
          ]
        ],
        preprocessor: Unifex
      ],
      pa_devices: [
        interface: :nif,
        sources: ["pa_devices.c"],
        os_deps: [
          portaudio: [
            {:precompiled, Membrane.PrecompiledDependencyProvider.get_dependency_url(:portaudio)},
            {:pkg_config, "portaudio-2.0"}
          ]
        ],
        preprocessor: Unifex
      ]
    ] ++ os_specific(Bundlex.platform())
  end

  defp os_specific(:macosx) do
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
