defmodule Bugsnag.Mixfile do
  use Mix.Project

  def project do
    [app: :bugsnag,
     version: "1.4.0",
     elixir: "~> 1.0",
     package: package(),
     elixirc_paths: elixirc_paths(Mix.env),
     description: """
       An Elixir interface to the Bugsnag API
     """,
     deps: deps()]
  end

  def package do
    [contributors: ["Jared Norman", "Andrew Harvey"],
     maintainers: ["Andrew Harvey"],
     licenses: ["MIT"],
     links: %{github: "https://github.com/jarednorman/bugsnag-elixir"}]
  end

  def application do
    [applications: [:httpotion, :logger],
     mod: {Bugsnag, []}]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_),     do: ["lib"]

  defp deps do
    [{:httpotion, "~> 3.0"},
     {:poison, "~> 1.5 or ~> 2.0"},
     {:ex_doc, ">= 0.0.0", only: :dev},
     {:meck, "~> 0.8.3", only: :test}]
  end
end
