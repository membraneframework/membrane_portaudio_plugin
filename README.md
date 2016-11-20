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

This should create a loopback between default capture and playback device:

```elixir
{:ok, sink} = Membrane.Element.PortAudio.Sink.start_link(%Membrane.Element.PortAudio.SinkOptions{})
{:ok, source} = Membrane.Element.PortAudio.Source.start_link(%Membrane.Element.PortAudio.SourceOptions{})
Membrane.Element.link(source, sink)
Membrane.Element.play(sink)
Membrane.Element.play(source)
```


# Authors

* Marcin Lewandowski

Ringbuffer code ported from PortAudio:

* Author: Phil Burk, http://www.softsynth.com
* modified for SMP safety on Mac OS X by Bjorn Roche
* modified for SMP safety on Linux by Leland Lucius
* also, allowed for const where possible
* modified for multiple-byte-sized data elements by Sven Fischer
