defmodule TypedStructor.MixProject do
  use Mix.Project

  @version "0.4.2"
  @source_url "https://github.com/elixir-typed-structor/typed_structor"

  def project do
    [
      app: :typed_structor,
      description: "TypedStructor is a library for defining structs with types effortlessly.",
      version: @version,
      elixir: "~> 1.14",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      consolidate_protocols: Mix.env() != :test,
      deps: deps(),
      name: "TypedStructor",
      source: @source_url,
      homepage_url: @source_url,
      docs: [
        main: "readme",
        source_url: @source_url,
        source_ref: "v#{@version}",
        extra_section: "Guides",
        groups_for_extras: [
          Guides: ~r<(guides/[^\/]+\.md)|(README.md)>,
          Plugins: ~r{guides/plugins/[^\/]+\.md}
        ],
        extras: [
          {"CHANGELOG.md", [title: "Changelog"]},

          # guides
          {"README.md", [title: "Introduction"]},
          "guides/migrate_from_typed_struct.md",

          # plugins
          {"guides/plugins/introduction.md", [title: "Introduction"]},
          "guides/plugins/registering_plugins_globally.md",
          "guides/plugins/accessible.md",
          "guides/plugins/reflection.md",
          "guides/plugins/doc_fields.md",
          "guides/plugins/type_only_on_ecto_schema.md",
          "guides/plugins/primary_key_and_timestamps.md",
          "guides/plugins/derive_jason.md",
          "guides/plugins/derive_enumerable.md"
        ],
        nest_modules_by_prefix: [
          TypedStructor.Definer
        ]
      ],
      package: [
        name: "typed_structor",
        licenses: ["MIT"],
        links: %{
          "Changelog" => "https://hexdocs.pm/typed_structor/changelog.html",
          "GitHub" => @source_url
        }
      ],
      test_coverage: [
        summary: [threshold: 100],
        ignore_modules: [
          TypedStructor.Definition,
          TypedStructor.GuideCase,
          TypedStructor.TestCase
        ]
      ],
      aliases: aliases()
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:ex_doc, "~> 0.31", only: :dev, runtime: false},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false},
      {:ecto, "~> 3.0", only: [:dev, :test], optional: true},
      {:jason, "~> 1.4", only: [:dev, :test], optional: true},
      {:makeup_diff, "~> 0.1", only: [:test, :dev], runtime: false}
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp aliases do
    [
      check: [
        "format",
        "compile --warning-as-errors",
        "credo --strict",
        "dialyzer"
      ]
    ]
  end
end
