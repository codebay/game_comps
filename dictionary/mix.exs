defmodule Dictionary.MixProject do
  use Mix.Project

  def project do
    [
      app: :dictionary,
      version: "0.1.0",
      elixir: "~> 1.7",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      mod: {Dictionary.WordListComp, []},
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:component, git: "https://github.com/pragdave/component.git"}
    ]
  end
end
