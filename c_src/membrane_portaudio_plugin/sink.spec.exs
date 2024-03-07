alias Membrane.PortAudio.Sink.Native

module Native

state_type "SinkState"

spec create(
       demand_handler :: pid,
       clock :: pid,
       device_id :: int,
       sample_rate :: int,
       channels :: int,
       sample_format :: atom,
       ringbuffer_size :: int,
       pa_buffer_size :: int,
       latency :: atom
     ) :: {:ok :: label, {latency_ms :: int, state}} | {:error :: label, reason :: atom}

spec write_data(payload, state) :: (:ok :: label) | {:error :: label, :overrun :: label}

spec destroy(state) :: :ok

sends {Native, :destroy :: label, state}
sends {:portaudio_demand :: label, size :: int}
sends {:membrane_clock_update :: label, {frames :: int, sample_rate_ms :: int}}
