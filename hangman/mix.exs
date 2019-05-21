defmodule Hangman.MixProject do
  use Mix.Project

  def project do
    [
      app: :hangman,
      version: "0.1.0",
      elixir: "~> 1.7",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      mod: {Hangman.GameComp, []},
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:component, git: "https://github.com/pragdave/component.git"},
      {:dictionary, path: "../dictionary"}
    ]
  end
end
