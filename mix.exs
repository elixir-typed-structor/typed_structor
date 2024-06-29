defmodule TypedStructor.MixProject do
  use Mix.Project

  def project do
    [
      app: :typed_structor,
      description: "TypedStructor is a library for defining structs with types effortlessly.",
      version: "0.1.3",
      elixir: "~> 1.14",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      name: "TypedStructor",
      source: "https://github.com/elixir-typed-structor/typed_structor",
      homepage_url: "https://github.com/elixir-typed-structor/typed_structor",
      docs: [
        main: "TypedStructor",
        extra_section: "Guides",
        extras: [
          "README.md",
          "guides/migrate_from_typed_struct.md",
          "CHANGELOG.md"
        ]
      ],
      package: [
        name: "typed_structor",
        licenses: ["MIT"],
        links: %{
          "GitHub" => "https://github.com/Byzanteam/jet-ext"
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
      {:makeup_diff, "~> 0.1", only: [:test, :dev], runtime: false}
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]
end
