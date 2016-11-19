ERL_INCLUDE_PATH=/usr/local/Cellar/erlang/19.0.2/lib/erlang/usr/include/
PORTAUDIO_INCLUDE_PATH=/usr/local/Cellar/portaudio/19.20140130/include/
PORTAUDIO_LIB_PATH=/usr/local/Cellar/portaudio/19.20140130/lib/

linux: unix

darwin: unix

unix: priv/membrane_element_portaudio_source.so priv/membrane_element_portaudio_sink.so

priv/membrane_element_portaudio_source.so:
	cc -fPIC -I../membrane_common_c/include -I./deps/membrane_common_c/include -I$(ERL_INCLUDE_PATH) -I$(PORTAUDIO_INCLUDE_PATH) -L$(PORTAUDIO_LIB_PATH) -lportaudio -dynamiclib -undefined dynamic_lookup -o membrane_element_portaudio_source.so c_src/source.c

priv/membrane_element_portaudio_sink.so:
	cc -fPIC -I../membrane_common_c/include -I./deps/membrane_common_c/include -I$(ERL_INCLUDE_PATH) -I$(PORTAUDIO_INCLUDE_PATH) -L$(PORTAUDIO_LIB_PATH) -lportaudio -dynamiclib -undefined dynamic_lookup -o membrane_element_portaudio_sink.so c_src/sink.c
