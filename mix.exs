defmodule GraphqlExample.MixProject do
  use Mix.Project

  def project do
    [
      app: :graphql_example,
      version: "0.1.0",
      elixir: "~> 1.6",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      mod: { GraphqlExample, [] },
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:plug, "~> 1.5"},
      {:absinthe_plug, "~> 1.4"},
      {:absinthe, "~> 1.4"},
      {:poison, "~> 3.1"},
      {:httpoison, "~> 1.0"},
      {:cowboy, "~> 2.2"},
      {:mime, "~> 1.2"},
      {:guardian, "~> 1.0"},

      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"},
    ]
  end
end