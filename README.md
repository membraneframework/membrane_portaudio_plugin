# Membrane PortAudio plugin

[![Hex.pm](https://img.shields.io/hexpm/v/membrane_portaudio_plugin.svg)](https://hex.pm/packages/membrane_portaudio_plugin)
[![API Docs](https://img.shields.io/badge/api-docs-yellow.svg?style=flat)](https://hexdocs.pm/membrane_portaudio_plugin/)
[![CircleCI](https://circleci.com/gh/membraneframework/membrane_portaudio_plugin.svg?style=svg)](https://circleci.com/gh/membraneframework/membrane_portaudio_plugin)

Plugin that can be used to capture and play sound using multiplatform PortAudio library.

## Installation

Add the following line to your `deps` in `mix.exs`. Run `mix deps.get`.

```elixir
	{:membrane_portaudio_plugin, "~> 0.16.1"}
```

You also need to have [PortAudio](http://portaudio.com/) installed.
For Mac OS you can install it via Homebrew: `brew install portaudio`, on Debian via apt-get: `apt-get install portaudio19-dev`.

## Sample usage

Playing below pipeline should play a raw file to default output device.

```elixir
defmodule Membrane.ReleaseTest.Pipeline do
  use Membrane.Pipeline

  alias Membrane.PortAudio

  @impl true
  def handle_init(_ctx, _opts) do
    structure = 
      child(:file_src, %Membrane.Element.File.Source{location: "file.raw"})
      |> child(:pa_sink, PortAudio.Sink)
    
    {[spec: structure], %{}}
  end
end
```

And this one should forward sound from default input to default output. DO NOT USE WITHOUT HEADPHONES to avoid audio feedback.

```elixir
defmodule Membrane.ReleaseTest.Pipeline do
  use Membrane.Pipeline

  alias Membrane.PortAudio

  @impl true
  def handle_init(_ctx, _opts) do
    structure =
      child(:pa_src, PortAudio.Source)
      |> child(:pa_sink, PortAudio.Sink)

    {[spec: structure], %{}}
  end
end
```

## Testing

Tests contain some cases that use portaudio stuff instead of mocking. Such cases require presence of at least one input and output soundcard, thus they are disabled by default. To enable them, run
```
mix test --include soundcard
```

## Copyright and License

Copyright 2018, [Software Mansion](https://swmansion.com/?utm_source=git&utm_medium=readme&utm_campaign=membrane-portaudio-plugin)

[![Software Mansion](https://logo.swmansion.com/logo?color=white&variant=desktop&width=200&tag=membrane-github)](https://swmansion.com/?utm_source=git&utm_medium=readme&utm_campaign=membrane-portaudio-plugin)

Licensed under the [Apache License, Version 2.0](LICENSE)
