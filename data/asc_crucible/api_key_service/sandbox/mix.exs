defmodule ApiKeyService.MixProject do
  use Mix.Project

  def project do
    [
      app: :api_key_service,
      version: "0.1.0",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: []
    ]
  end
end
