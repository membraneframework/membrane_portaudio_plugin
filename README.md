# Membrane Multimedia Framework: PortAudio Element

[![CircleCI](https://circleci.com/gh/membraneframework/membrane-element-portaudio.svg?style=svg)](https://circleci.com/gh/membraneframework/membrane-element-portaudio)

This package provides [Membrane Multimedia Framework](https://membraneframework.org)
elements that can be used to capture and play sound
using multiplatform PortAudio library.

Documentation is available at [HexDocs](https://hexdocs.pm/membrane_element_portaudio/).

## Installation

Add the following line to your `deps` in `mix.exs`. Run `mix deps.get`.

```elixir
{:membrane_element_portaudio, "~> 0.2.0"}
```

You also need to have [PortAudio](http://portaudio.com/) installed.

## Sample usage

Playing below pipeline should play a raw file to default output device.

```elixir
defmodule Membrane.ReleaseTest.Pipeline do
  use Membrane.Pipeline
  alias Pipeline.Spec
  alias Membrane.Element.{PortAudio, File}

  @impl true
  def handle_init(_) do
    children = [
      file_src: %File.Source{location: "file.raw"},
      pa_sink: PortAudio.Sink
    ]
    links = %{
      {:file_src, :output} => {:pa_sink, :input}
    }

    {{:ok, %Spec{children: children, links: links}}, %{}}
  end
end
```

And this one should forward sound from default input to default output. DO NOT USE WITHOUT HEADPHONES to avoid audio feedback.

```elixir
defmodule Membrane.ReleaseTest.Pipeline do
  use Membrane.Pipeline
  alias Pipeline.Spec
  alias Membrane.Element.PortAudio

  @impl true
  def handle_init(_) do
    children = [
      pa_src: PortAudio.Source,
      pa_sink: PortAudio.Sink
    ]
    links = %{
      {:pa_src, :output} => {:pa_sink, :input}
    }

    {{:ok, %Spec{children: children, links: links}}, %{}}
  end
end
```

## Testing

Tests contain some cases that use portaudio stuff instead of mocking. Such cases require presence of at least one input and output soundcard, thus they are disabled by default. To enable them, run
```
mix test --include soundcard
```

## Copyright and License

Copyright 2018, [Software Mansion](https://swmansion.com/?utm_source=git&utm_medium=readme&utm_campaign=membrane-element-portaudio)

[![Software Mansion](https://membraneframework.github.io/static/logo/swm_logo_readme.png)](
https://swmansion.com/?utm_source=git&utm_medium=readme&utm_campaign=membrane-element-portaudio)

Licensed under the [Apache License, Version 2.0](LICENSE)
