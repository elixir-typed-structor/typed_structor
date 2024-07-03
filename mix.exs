defmodule TypedStructor.MixProject do
  use Mix.Project

  @source_url "https://github.com/elixir-typed-structor/typed_structor"

  def project do
    [
      app: :typed_structor,
      description: "TypedStructor is a library for defining structs with types effortlessly.",
      version: "0.2.0",
      elixir: "~> 1.14",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      consolidate_protocols: Mix.env() != :test,
      deps: deps(),
      name: "TypedStructor",
      source: @source_url,
      homepage_url: @source_url,
      docs: [
        main: "TypedStructor",
        source_url: @source_url,
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
          "guides/plugins/type_only_on_ecto_schema.md",
          "guides/plugins/primary_key_and_timestamps.md",
          "guides/plugins/derive_jason.md",
          "guides/plugins/derive_enumerable.md"
        ]
      ],
      package: [
        name: "typed_structor",
        licenses: ["MIT"],
        links: %{
          "GitHub" => @source_url
        }
      ]
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
end
