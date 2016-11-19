# Membrane Multimedia Framework: PortAudio Element

This package provides elements that can be used to capture and play sound
using multiplatform PortAudio library.


# Installation

Add the following line to your `deps` in `mix.exs`.  Run `mix deps.get`.

```elixir
{:membrane_element_portaudio, git: "git@bitbucket.org:radiokit/membrane-element-portaudio.git"}
```

Then add the following line to your `applications` in `mix.exs`.

```elixir
:membrane_element_portaudio
```

# Sample usage

```elixir
{:ok, sink} = Membrane.Element.PortAudio.Sink.start_link(%Membrane.Element.PortAudio.SinkOptions{})
{:ok, source} = Membrane.Element.PortAudio.Source.start_link(%Membrane.Element.PortAudio.SourceOptions{})
Membrane.Element.link(source, sink)
Membrane.Element.play(sink)
Membrane.Element.play(source)
```


# Authors

Marcin Lewandowski
