alias Membrane.Element.PortAudio.Sink.Native

module Native

spec create(
       demand_handler :: pid,
       endpoint_id :: int,
       ringbuffer_size :: int,
       pa_buffer_size :: int,
       latency :: atom
     ) :: {:ok :: label, state} | {:error :: label, reason :: atom}

spec write_data(payload, state) :: (:ok :: label) | {:error :: label, :overrun :: label}

spec destroy(state) :: :ok

sends {Native, :destroy :: label, state}
sends {:demand :: label, size :: int}
