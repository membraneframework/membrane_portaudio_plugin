[
  inputs: [
    "{lib,test,config}/**/*.{ex,exs}",
    "c_src/**/*.spec.exs",
    "*.exs",
    ".formatter.exs"
  ],
  import_deps: [:membrane_core, :bundlex, :unifex]
]
