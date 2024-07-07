locals_without_parens = [field: 2, field: 3, parameter: 1, parameter: 2, plugin: 1, plugin: 2]

[
  inputs: ["{mix,.formatter}.exs", "{config,lib,test}/**/*.{ex,exs}"],
  import_deps: [:ecto],
  locals_without_parens: [{:assert_type, 2} | locals_without_parens],
  export: [
    locals_without_parens: locals_without_parens
  ]
]
