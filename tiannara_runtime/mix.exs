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
      docs: docs(),
      compilers: Mix.compilers(),
      elixirc_options: [warnings_as_errors: false]
    ]
  end

  # Run "mix help compile.app" to learn about applications
  def application do
    [
      extra_applications: [:logger, :mnesia],
      mod: {TiannaraRuntime.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies
  defp deps do
    [
      # Forward provenance (Council-authorized Stage 1/2 substrate; wired into
      # the OPC ExecutionRuntime boundary in Stage 3)
      {:forward_provenance, path: "../forward_provenance"},

      # Phoenix framework for API and real-time signaling
      {:phoenix, "~> 1.7.0"},
      
      # Phoenix LiveView for ecological dashboard
      {:phoenix_live_view, "~> 0.20.0"},

      # HTTP server adapter for Phoenix
      {:plug_cowboy, "~> 2.6"},
      
      # NATS client for Python/Elixir bridge (Phase 2 integration)
      {:gnat, "~> 1.0"},
      
      # UUID generation for world IDs and trace IDs
      {:uuid, "~> 1.1"},
      
      # JSON encoding/decoding for event payloads
      {:jason, "~> 1.4"},
      
      # HTTP client for external integrations
      {:req, "~> 0.4"},
      
      # Documentation generation
      {:ex_doc, "~> 0.31", only: :dev, runtime: false},
      
      # Testing framework enhancements
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:propcheck, "~> 1.4", only: [:test, :dev]},

      # Telemetry for metrics exports (Phases 11-16)
      {:telemetry, "~> 1.2"},
      {:telemetry_metrics, "~> 1.0"},

      # Rust NIF integration
      {:rustler, "~> 0.36.0"}
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
        "Observability Layer": [
          TiannaraRuntime.Observability.StreamProcessor,
          TiannaraRuntime.Observability.TestPublisher
        ],
        "Predictive Layer (Phase 4A)": [
          TiannaraRuntime.Predictive.StateSnapshot,
          TiannaraRuntime.Predictive.ForwardSimulation
        ],
        "Identity Layer (Phase 4B)": [
          TiannaraRuntime.Identity.CoalitionHistory,
          TiannaraRuntime.Identity.Fingerprint,
          TiannaraRuntime.Identity.SpeciesRegistry,
          TiannaraRuntime.Identity.Tracker
        ],
        "Causality Layer (Phase 4C)": [
          TiannaraRuntime.Causality.TracePropagation,
          TiannaraRuntime.Causality.CausalGraph,
          TiannaraRuntime.Causality.TraceQuery
        ],
        "Meta-Stability Layer (Phase 4D)": [
          TiannaraRuntime.MetaStability.StabilityMetrics,
          TiannaraRuntime.MetaStability.ParameterAdjustment,
          TiannaraRuntime.MetaStability.StabilityOptimizer
        ],
        "MSCL - Meta-Stability Constraint Layer (Phase 5F.5)": [
          Tiannara.MSCL.Supervisor,
          Tiannara.MSCL.ConstraintEngine,
          Tiannara.MSCL.BudgetTracker,
          Tiannara.MSCL.DivergenceAnalyzer,
          Tiannara.MSCL.EvaporationEngine
        ],
        "OLEF - Ontological Load Equilibrium Field (Phase 5F.5)": [
          Tiannara.OLEF.FieldSupervisor,
          Tiannara.OLEF.PressureSolver,
          Tiannara.OLEF.GradientRouter,
          Tiannara.OLEF.DiffusionModel,
          Tiannara.OLEF.NodeRegistry
        ],
        "NATS Pressure Streaming (Phase 5F.5)": [
          Tiannara.NATS.PressureStream
        ],
        "NATS Distributed Reality Mesh (Phase 5F.x)": [
          Tiannara.Meta.Mesh.Supervisor,
          Tiannara.Meta.Mesh.RealityBus,
          Tiannara.Meta.Mesh.ObserverRouter,
          Tiannara.Meta.OLEF.MeshBalancer,
          Tiannara.Meta.Mesh.ChronogramSync,
          Tiannara.Meta.Mesh.RealityFirewall
        ],
        "OPC - Observer Physics Compiler (Phase 5F.6)": [
          Tiannara.OPC.Supervisor,
          Tiannara.OPC.API.CompileAPI,
          Tiannara.OPC.Parser.Lexer,
          Tiannara.OPC.Parser.Parser,
          Tiannara.OPC.Parser.AST,
          Tiannara.OPC.Validator.SymbolicValidator,
          Tiannara.OPC.Validation.TensorConstraintSolver,
          Tiannara.OPC.Validation.SingularityDetector,
          Tiannara.OPC.Validation.LoopAnalyzer,
          Tiannara.OPC.Validation.SymbolicSimplifier,
          Tiannara.OPC.AOR.Regularizer,
          Tiannara.OPC.OIR.IRBuilder,
          Tiannara.OPC.Compiler.GPUCompiler,
          Tiannara.OPC.Compiler.ShaderCache,
          Tiannara.OPC.Compiler.KernelOptimizer,
          Tiannara.OPC.Runtime.ExecutionRuntime,
          Tiannara.OPC.Runtime.SandboxInjector,
          Tiannara.OPC.Runtime.ChronogramBridge,
          Tiannara.NATS.OPCBus
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
