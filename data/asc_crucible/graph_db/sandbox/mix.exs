defmodule GraphDb.MixProject do
  use Mix.Project

  def project do
    [
      app: :graph_db,
      version: "0.1.0",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: []
    ]
  end
end
