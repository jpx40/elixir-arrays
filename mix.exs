defmodule Array.Mixfile do
  use Mix.Project
  @source_url "https://github.com/Qqwy/elixir-Array"

  def project do
    [
      app: :Array,
      version: "2.1.1",
      elixir: "~> 1.9",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      name: "Array",
      description: description(),
      source_url: @source_url,
      package: package(),
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test
      ],
      docs: docs()
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:extractable, "~> 1.0"},
      {:insertable, "~> 1.0"},
      # {:fun_land, "~> 0.9.2", optional: true},
      {:ex_doc, "~>  0.38.1", only: :dev, runtime: false},
      {:dialyxir, "~> 1.4", only: [:dev], runtime: false},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:excoveralls, "~> 0.18.5", only: [:test]},
      {:benchee, "~> 1.4", only: [:dev]},
      {:benchee_csv, "~> 1.0", only: [:dev]},
      {:benchee_markdown, "~> 0.2", only: [:dev]},
      {:benchee_html, "~> 1.0", only: [:dev]}
    ]
  end

  defp description do
    """
    Well-structured Array with fast random-element-access for Elixir, offering a common interface with multiple implementations (MapArray, Erlang :array, etc.) with varying performance guarantees that can be switched in your configuration.
    """
  end

  defp package() do
    [
      name: :Array,
      files: ["lib", "mix.exs", "README*"],
      maintainers: ["Qqwy/Wiebe-Marten Wijnja"],
      licenses: ["Apache 2.0"],
      links: %{"GitHub" => @source_url}
    ]
  end

  defp docs() do
    [
      main: "Array",
      logo: "brand/logo_text.png",
      groups_for_modules: [
        Main: [Array],
        Implementations: ~r{^Array.Implementations},
        "For Implementers": [Array.Protocol, Array.CommonProtocolImplementations],
        Other: ~r"^.*"
      ],
      nest_modules_by_prefix: [Array, Array.Implementations]
    ]
  end
end
