defmodule Tryelixir.Mixfile do
  use Mix.Project

  def project do
    [app: :tryelixir,
     version: "0.0.1",
     elixir: ">= 1.0.0",
     deps: deps]
  end

  def application do
    [mod: {Tryelixir, []},
     applications: [:logger, :cowboy]]
  end

  defp deps do
    [{:cowboy, github: "ninenines/cowboy", tag: "1.0.1"}]
  end
end
