defmodule Membrane.Element.PortAudio.Mixfile do
  use Mix.Project

  def project do
    [app: :membrane_element_portaudio,
     compilers: ["membrane.compile.c"] ++ Mix.compilers,
     version: "0.0.1",
     elixir: "~> 1.3",
     elixirc_paths: elixirc_paths(Mix.env),
     description: "Membrane Multimedia Framework (PortAudio Element)",
     maintainers: ["Marcin Lewandowski"],
     licenses: ["LGPL"],
     name: "Membrane Element: PortAudio",
     source_url: "https://bitbucket.com/radiokit/membrane-element-portaudio",
     preferred_cli_env: [espec: :test],
     deps: deps]
  end


  def application do
    [applications: [
      :membrane_core
    ], mod: {Membrane.Element.PortAudio, []}]
  end


  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_),     do: ["lib",]


  defp deps do
    [
      {:membrane_core, git: "git@bitbucket.org:radiokit/membrane-core.git"},
      {:membrane_common_c, git: "git@bitbucket.org:radiokit/membrane-common-c.git"},
      {:membrane_caps_audio_raw, git: "git@bitbucket.org:radiokit/membrane-caps-audio-raw.git"},
    ]
  end
end
