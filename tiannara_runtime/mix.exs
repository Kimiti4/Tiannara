defmodule TiannaraRuntime.MixProject do
  use Mix.Project

  def project do
    [
      app: :tiannara_runtime,
      version: "0.1.0",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: "Tiannara Cognitive Ecology Runtime - Phase 1 Hybrid Architecture",
      package: package(),
      docs: docs()
    ]
  end

  # Run "mix help compile.app" to learn about applications
  def application do
    [
      extra_applications: [:logger],
      mod: {TiannaraRuntime.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies
  defp deps do
    [
      # Phoenix framework for API and real-time signaling
      {:phoenix, "~> 1.7.0"},
      
      # Phoenix LiveView for ecological dashboard
      {:phoenix_live_view, "~> 0.20.0"},
      
      # NATS client for Python/Elixir bridge (Phase 2 integration)
      {:gnat, "~> 1.0"},
      
      # JSON encoding/decoding for event payloads
      {:jason, "~> 1.4"},
      
      # HTTP client for external integrations
      {:req, "~> 0.4"},
      
      # Documentation generation
      {:ex_doc, "~> 0.31", only: :dev, runtime: false},
      
      # Testing framework enhancements
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false}
    ]
  end

  defp package do
    [
      name: "tiannara_runtime",
      licenses: ["MIT"],
      links: %{
        "GitHub" => "https://github.com/tiannara/tiannara-mindcache-prosthetic"
      }
    ]
  end

  defp docs do
    [
      main: "readme",
      extras: ["README.md"],
      groups_for_modules: [
        "GRCC Ecology": [
          TiannaraRuntime.GRCC.Identity,
          TiannaraRuntime.GRCC.EcologySupervisor
        ],
        "CIS Immune System": [
          TiannaraRuntime.CIS.Supervisor,
          TiannaraRuntime.CIS.EntropyMonitor,
          TiannaraRuntime.CIS.DiversityRegulator,
          TiannaraRuntime.CIS.CollapseDetector,
          TiannaraRuntime.CIS.RecoveryOrchestrator
        ],
        "NATS Bridge": [
          TiannaraRuntime.NATS.Supervisor,
          TiannaraRuntime.NATS.Publisher,
          TiannaraRuntime.NATS.Subscriber,
          TiannaraRuntime.NATS.ConnectionManager
        ],
        "AEO Execution": [
          TiannaraRuntime.AEO.Supervisor
        ],
        "Interface Layer": [
          TiannaraRuntime.Interface.Supervisor,
          TiannaraRuntime.SignalBus.Supervisor,
          TiannaraRuntime.IdentityRegistry
        ]
      ]
    ]
  end
end
