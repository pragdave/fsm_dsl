defmodule FsmDsl.Mixfile do
  use Mix.Project

  def project do
    [ app:     :fsm_dsl,
      version: "0.0.1",
      elixir:  "~> 0.10.1-dev",
      deps:    deps
    ]
  end

  def application do
    []
  end

  defp deps do
    [ 
       {:meck,  github: "eproxus/meck" }
    ]
  end
end
