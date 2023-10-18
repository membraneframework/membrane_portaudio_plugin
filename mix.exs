defmodule Membrane.PortAudio.Mixfile do
  use Mix.Project

  @github_url "https://github.com/membraneframework/membrane_portaudio_plugin"
  @version "0.17.1"

  def project do
    [
      app: :membrane_portaudio_plugin,
      compilers: [:unifex, :bundlex] ++ Mix.compilers(),
      version: @version,
      elixir: "~> 1.12",
      elixirc_paths: elixirc_paths(Mix.env()),
      deps: deps(),
      dialyzer: dialyzer(),
      aliases: [pa_devices: "eval 'Membrane.PortAudio.print_devices()'"],

      # hex
      description: "Raw audio retriever and player based on PortAudio",
      package: package(),

      # docs
      name: "Membrane PortAudio plugin",
      source_url: @github_url,
      homepage_url: "https://membrane.stream",
      docs: docs()
    ]
  end

  def application do
    [extra_applications: [], mod: {Membrane.PortAudio, []}]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      {:membrane_core, "~> 0.12.7"},
      {:membrane_common_c, "~> 0.15.0"},
      {:bunch, "~> 1.5"},
      {:membrane_raw_audio_format, "~> 0.11.0"},
      {:bundlex, "~> 1.2"},
      # Testing
      {:mockery, "~> 2.1", runtime: false},
      # Development
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false},
      {:dialyxir, ">= 0.0.0", only: :dev, runtime: false},
      {:credo, ">= 0.0.0", only: :dev, runtime: false}
    ]
  end

  defp dialyzer() do
    opts = [
      flags: [:error_handling]
    ]

    if System.get_env("CI") == "true" do
      # Store PLTs in cacheable directory for CI
      [plt_local_path: "priv/plts", plt_core_path: "priv/plts"] ++ opts
    else
      opts
    end
  end

  defp docs do
    [
      main: "readme",
      extras: ["README.md", "LICENSE"],
      nest_modules_by_prefix: [
        Membrane.PortAudio
      ],
      source_ref: "v#{@version}",
      formatters: ["html"]
    ]
  end

  defp package do
    [
      maintainers: ["Membrane Team"],
      licenses: ["Apache-2.0"],
      links: %{
        "GitHub" => @github_url,
        "Membrane Framework Homepage" => "https://membraneframework.org"
      },
      files: ["lib", "c_src", "mix.exs", "README*", "LICENSE*", ".formatter.exs", "bundlex.exs"]
    ]
  end
end
