defmodule TiannaraAudit.MixProject do
  use Mix.Project

  def project do
    [
      app: :tiannara_audit,
      version: "1.0.0",
      elixir: "~> 1.18",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      escript: [main_module: TiannaraAudit]
    ]
  end

  def application do
    [extra_applications: [:crypto, :logger]]
  end

  defp deps do
    [{:jason, "~> 1.4"}]
  end
end
