# Membrane Multimedia Framework: PortAudio Element

This package provides elements that can be used to capture and play sound
using multiplatform PortAudio library.

# Installation

Add the following line to your `deps` in `mix.exs`. Run `mix deps.get`.

```elixir
{:membrane_element_portaudio, git: "git@github.com/membraneframework/membrane-element-portaudio.git"}
```

You also need to have [PortAudio](http://portaudio.com/) installed.

# Sample usage

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
      {:file_src, :source} => {:pa_sink, :sink}
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
      {:pa_src, :source} => {:pa_sink, :sink, pull_buffer: [toilet: true]}
    }

    {{:ok, %Spec{children: children, links: links}}, %{}}
  end
end
```
