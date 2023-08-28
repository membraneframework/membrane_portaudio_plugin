alias Membrane.PortAudio.Source.Native

module Native

state_type "SourceState"

spec create(
       destination :: pid,
       endpoint_id :: int,
       pa_buffer_size :: int,
       latency :: atom,
       sample_format :: atom,
       max_channels :: int,
       sample_rate :: int
     ) ::
       {:ok :: label, state, channels :: int, sample_rate :: int}
       | {:error :: label, reason :: atom}

spec destroy(state) :: :ok

sends {Native, :destroy :: label, state}
sends {:portaudio_payload :: label, payload}
