defmodule FsmDsl.Mixfile do
  use Mix.Project

  def project do
    [ app:     :fsm_dsl,
      version: "0.0.1",
      elixir:  "~> 0.10.1-dev",
      deps:    deps(Mix.env)
    ]
  end

  def application do
    []
  end

  defp deps(:prod), do: [ ]
  defp deps(_),     do: [ {:meck,  github: "eproxus/meck" } ]

end
