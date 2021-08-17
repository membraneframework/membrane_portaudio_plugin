defmodule Membrane.PortAudio.Mixfile do
  use Mix.Project

  @github_url "https://github.com/membraneframework/membrane_portaudio_plugin"
  @version "0.8.0"

  def project do
    [
      app: :membrane_portaudio_plugin,
      compilers: [:unifex, :bundlex] ++ Mix.compilers(),
      version: @version,
      elixir: "~> 1.10",
      elixirc_paths: elixirc_paths(Mix.env()),
      description: "Raw audio retriever and player based on PortAudio",
      package: package(),
      name: "Membrane PortAudio plugin",
      source_url: @github_url,
      docs: docs(),
      deps: deps()
    ]
  end

  def application do
    [extra_applications: [], mod: {Membrane.PortAudio, []}]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      {:membrane_core, "~> 0.7.0"},
      {:membrane_common_c, "~> 0.8.0"},
      {:bunch, "~> 1.3.0"},
      {:unifex, "~> 0.4.0"},
      {:membrane_caps_audio_raw, "~> 0.4.0"},
      {:bundlex, "~> 0.4.0"},
      {:mockery, "~> 2.1", runtime: false},
      {:ex_doc, "~> 0.19", only: :dev, runtime: false}
    ]
  end

  defp docs do
    [
      main: "readme",
      extras: ["README.md", "LICENSE"],
      nest_modules_by_prefix: [
        Membrane.PortAudio
      ],
      source_ref: "v#{@version}"
    ]
  end

  defp package do
    [
      maintainers: ["Membrane Team"],
      licenses: ["Apache 2.0"],
      links: %{
        "GitHub" => @github_url,
        "Membrane Framework Homepage" => "https://membraneframework.org"
      },
      files: ["lib", "c_src", "mix.exs", "README*", "LICENSE*", ".formatter.exs", "bundlex.exs"]
    ]
  end
end
