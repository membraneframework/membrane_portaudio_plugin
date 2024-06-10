# Membrane PortAudio plugin

[![Hex.pm](https://img.shields.io/hexpm/v/membrane_portaudio_plugin.svg)](https://hex.pm/packages/membrane_portaudio_plugin)
[![API Docs](https://img.shields.io/badge/api-docs-yellow.svg?style=flat)](https://hexdocs.pm/membrane_portaudio_plugin/)
[![CircleCI](https://circleci.com/gh/membraneframework/membrane_portaudio_plugin.svg?style=svg)](https://circleci.com/gh/membraneframework/membrane_portaudio_plugin)

The plugin that captures and plays sound using the multiplatform PortAudio library.

## Installation

Add the following line to your `deps` in `mix.exs`. Run `mix deps.get`.

```elixir
{:membrane_portaudio_plugin, "~> 0.19.2"}
```

This package depends on the [PortAudio](http://portaudio.com/) library. The precompiled build will be pulled and linked automatically. However, should there be any problems, consider installing it manually.

When running on linux [ALSA (alsa-lib)](https://github.com/alsa-project/alsa-lib) needs to be present on the system for the precompiled build to work. In most cases it's installed by default, however in case it's not present you can install it manually.

### Manual instalation of dependencies
#### Ubuntu

```bash
sudo apt-get install alsa
```
```bash
sudo apt-get install portaudio19-dev
```

#### Arch/Manjaro

```bash
pacman -S alsa-lib
```
```bash
pacman -S portaudio
```

#### MacOS

```bash
brew install portaudio
```

## Tasks

The `mix pa_devices` task prints available audio devices and their IDs, which you can pass to the `Membrane.PortAudio.Source` or `Membrane.PortAudio.Sink`.

## Sample usage

The pipeline below should play a raw file to a default output device.

```elixir
defmodule Example.Pipeline do
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

And this one should forward sound from the default input to the default output. DO NOT USE WITHOUT HEADPHONES to avoid audio feedback.

```elixir
defmodule Example.Pipeline do
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

### Low latency

To reduce the latency of the sink and/or source, you can:
- set the `latency` option to `:low` to configure the sound card in the low latency mode,
- reduce the `portaudio_buffer_size` to make PortAudio produce/consume smaller audio chunks,

for example:

```elixir
child(:pa_src, %PortAudio.Source{latency: :low, portaudio_buffer_size: 32})
|> child(:pa_sink, %PortAudio.Sink{latency: :low, portaudio_buffer_size: 32})
```

## Testing

Tests contain some cases that use PortAudio stuff instead of mocking. Such cases require the presence of at least one input and output sound card, thus they are disabled by default. To enable them, run
```
mix test --include soundcard
```

## Copyright and License

Copyright 2018, [Software Mansion](https://swmansion.com/?utm_source=git&utm_medium=readme&utm_campaign=membrane-portaudio-plugin)

[![Software Mansion](https://logo.swmansion.com/logo?color=white&variant=desktop&width=200&tag=membrane-github)](https://swmansion.com/?utm_source=git&utm_medium=readme&utm_campaign=membrane-portaudio-plugin)

Licensed under the [Apache License, Version 2.0](LICENSE)
