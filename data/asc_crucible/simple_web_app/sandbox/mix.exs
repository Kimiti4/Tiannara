defmodule SimpleWebApp.MixProject do
  use Mix.Project

  def project do
    [
      app: :simple_web_app,
      version: "0.1.0",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: []
    ]
  end
end
