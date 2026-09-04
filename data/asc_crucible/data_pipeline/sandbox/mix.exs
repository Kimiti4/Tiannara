defmodule DataPipeline.MixProject do
  use Mix.Project

  def project do
    [
      app: :data_pipeline,
      version: "0.1.0",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: []
    ]
  end
end
