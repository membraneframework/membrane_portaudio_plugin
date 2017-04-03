use Mix.Config

config :membrane_element_portaudio, :bundlex_lib,
  macosx: [
    nif: [
      membrane_element_portaudio_source: [
        includes: [
          "../membrane_common_c/c_src",
          "./deps/membrane_common_c/c_src",
        ],
        sources: [
          "source.c",
        ],
        libs: [
        ],
        pkg_configs: [
          "portaudio-2.0",
        ]
      ],
      membrane_element_portaudio_sink: [
        includes: [
          "../membrane_common_c/c_src",
          "./deps/membrane_common_c/c_src",
        ],
        sources: [
          "pa_ringbuffer.c",
          "sink.c",
        ],
        libs: [
        ],
        pkg_configs: [
          "portaudio-2.0",
        ]
      ]
    ]
  ],
  windows32: [
    nif: [
      membrane_element_portaudio_source: [
        includes: [
          "../membrane_common_c/c_src",
          "./deps/membrane_common_c/c_src",
        ],
        sources: [
          "source.c",
        ],
        libs: [
        ]
      ],
      membrane_element_portaudio_sink: [
        includes: [
          "../membrane_common_c/c_src",
          "./deps/membrane_common_c/c_src",
        ],
        sources: [
          "pa_ringbuffer.c",
          "sink.c",
        ],
        libs: [
        ]
      ]
    ]
  ],
  windows64: [
    nif: [
      membrane_element_portaudio_source: [
        includes: [
          "../membrane_common_c/c_src",
          "./deps/membrane_common_c/c_src",
        ],
        sources: [
          "source.c",
        ],
        libs: [
        ]
      ],
      membrane_element_portaudio_sink: [
        includes: [
          "../membrane_common_c/c_src",
          "./deps/membrane_common_c/c_src",
        ],
        sources: [
          "pa_ringbuffer.c",
          "sink.c",
        ],
        libs: [
        ]
      ]
    ]
  ],
  linux: [
    nif: [
      membrane_element_portaudio_source: [
        includes: [
          "../membrane_common_c/c_src",
          "./deps/membrane_common_c/c_src",
        ],
        sources: [
          "source.c",
        ],
        libs: [
        ],
        pkg_configs: [
          "portaudio-2.0",
        ]
      ],
      membrane_element_portaudio_sink: [
        includes: [
          "../membrane_common_c/c_src",
          "./deps/membrane_common_c/c_src",
        ],
        sources: [
          "pa_ringbuffer.c",
          "sink.c",
        ],
        libs: [
        ],
        pkg_configs: [
          "portaudio-2.0",
        ]
      ],
    ]
]
