DARWIN_ERL_INCLUDE_PATH=/usr/local/Cellar/erlang/19.2/lib/erlang/usr/include/
DARWIN_PORTAUDIO_INCLUDE_PATH=/usr/local/Cellar/portaudio/19.20140130/include/
DARWIN_PORTAUDIO_LIB_PATH=/usr/local/Cellar/portaudio/19.20140130/lib/
LINUX_ERL_INCLUDE_PATH=/usr/local/erlang/usr/include/


darwin: darwin_membrane_element_portaudio_source darwin_membrane_element_portaudio_sink

darwin_membrane_element_portaudio_source:
	cc -fPIC -I../membrane_common_c/include -I./deps/membrane_common_c/include -I$(DARWIN_ERL_INCLUDE_PATH) -I$(DARWIN_PORTAUDIO_INCLUDE_PATH) -L$(DARWIN_PORTAUDIO_LIB_PATH) -lportaudio -dynamiclib -undefined dynamic_lookup -o membrane_element_portaudio_source.so c_src/source.c

darwin_membrane_element_portaudio_sink:
	cc -fPIC -I../membrane_common_c/include -I./deps/membrane_common_c/include -I$(DARWIN_ERL_INCLUDE_PATH) -I$(DARWIN_PORTAUDIO_INCLUDE_PATH) -L$(DARWIN_PORTAUDIO_LIB_PATH) -lportaudio -dynamiclib -undefined dynamic_lookup -o membrane_element_portaudio_sink.so c_src/sink.c c_src/pa_ringbuffer.c

linux: linux_membrane_element_portaudio_source linux_membrane_element_portaudio_sink

linux_membrane_element_portaudio_source:
	gcc -fPIC -I../membrane_common_c/include -I./deps/membrane_common_c/include -I$(LINUX_ERL_INCLUDE_PATH) -lportaudio -lasound -lm -lpthread -pthread -dynamiclib -undefined dynamic_lookup -o membrane_element_portaudio_source.so c_src/source.c

linux_membrane_element_portaudio_sink:
	gcc -fPIC -I../membrane_common_c/include -I./deps/membrane_common_c/include -I$(LINUX_ERL_INCLUDE_PATH) -lportaudio -lasound -lm -lpthread -pthread -dynamiclib -undefined dynamic_lookup -o membrane_element_portaudio_sink.so c_src/sink.c c_src/pa_ringbuffer.c
