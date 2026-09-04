defmodule AngularAdmin.MixProject do
  use Mix.Project

  def project do
    [
      app: :angular_admin,
      version: "0.1.0",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: []
    ]
  end
end
