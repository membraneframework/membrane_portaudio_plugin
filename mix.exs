defmodule Membrane.Element.PortAudio.Mixfile do
  use Mix.Project
  Application.put_env(:bundlex, :membrane_element_portaudio, __ENV__)

  def project do
    [
      app: :membrane_element_portaudio,
      compilers: [:bundlex] ++ Mix.compilers(),
      version: "0.0.1",
      elixir: "~> 1.6",
      elixirc_paths: elixirc_paths(Mix.env()),
      description: "Membrane Multimedia Framework (PortAudio Element)",
      package: package(),
      name: "Membrane Element: PortAudio",
      source_url: "https://github.com/membraneframework/membrane-element-portaudio",
      deps: deps()
    ]
  end

  def application do
    [extra_applications: [], mod: {Membrane.Element.PortAudio, []}]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      {:membrane_core, git: "git@github.com:membraneframework/membrane-core.git"},
      {:membrane_common_c, git: "git@github.com:membraneframework/membrane-common-c.git"},
      {:membrane_caps_audio_raw,
       git: "git@github.com:membraneframework/membrane-caps-audio-raw.git"},
      {:bundlex, git: "git@github.com:radiokit/bundlex.git"},
      {:mockery, "~> 2.1", runtime: false}
    ]
  end

  defp package do
    [
      maintainers: ["Membrane Team"],
      licenses: ["Apache 2.0"]
    ]
  end
end
