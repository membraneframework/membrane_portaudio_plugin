#import "AVFoundation/AVFoundation.h"
#import "erl_nif.h"

ERL_NIF_TERM request_mic(ErlNifEnv *env, int _argc,
                         const ERL_NIF_TERM _argv[]) {
  (void)_argc;
  (void)_argv;

  [AVCaptureDevice requestAccessForMediaType:AVMediaTypeAudio
                           completionHandler:^(BOOL granted) {
                             if (!granted) {
                               printf("Warning: microphone not authorized, you "
                                      "may get silence on input.\n");
                             }
                           }];

  return enif_make_atom(env, "ok");
}

static ErlNifFunc nif_funcs[] = {{"request_mic", 0, request_mic, 0}};

ERL_NIF_INIT(Elixir.Membrane.PortAudio.OSXPermissions.Nif, nif_funcs, NULL,
             NULL, NULL, NULL)
