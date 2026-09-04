defmodule Tiannara.MixProject do
  use Mix.Project

  def project do
    [
      app: :tiannara,
      version: "0.3.5",
      elixir: "~> 1.15",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      compilers: Mix.compilers(),
      elixirc_paths: elixirc_paths(Mix.env()),
      aliases: aliases(),
      releases: releases(),
      consolidate_protocols: Mix.env() != :test,
      build_embedded: false,
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test
      ],
      dialyzer: [
        plt_add_apps: [:erts, :kernel, :stdlib, :eex, :gettext, :jason],
        plt_core_path: "_build/plts",
        plt_file: "_build/plts/dialyzer.plt"
      ]
    ]
  end

  defp releases do
    [
      tiannara: [
        include_executables_for: [:unix, :windows],
        applications: [
          tiannara: :permanent,
          phoenix: :permanent,
          plug_cowboy: :permanent
        ],
        steps: [:assemble, :tar]
      ]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [
        :logger,
        :runtime_tools,
        :gnat,
        :jason,
        :crypto,
        :ssl,
        :inets
      ],
      mod: {Tiannara.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      # Core dependencies
      {:gnat, "~> 1.7"},
      {:jason, "~> 1.4"},
      {:uuid, "~> 1.1"},
      {:telemetry, "~> 1.2"},
      {:telemetry_metrics, "~> 1.0"},
      {:telemetry_poller, "~> 1.0"},
      
      # Web and Pipelines (PEO Phase 6F.4)
      {:phoenix, "~> 1.7"},
      {:phoenix_live_view, "~> 1.0"},
      {:phoenix_html, "~> 4.0"},
      {:plug_cowboy, "~> 2.7"},
      {:cors_plug, "~> 3.0"},
      {:protobuf, "~> 0.13"},
      {:gen_stage, "~> 1.2"},
      {:broadway, "~> 1.0"},
      
      # Math and computation
      {:nx, "~> 0.6"},
      
      # Data structures
      {:ets, "~> 0.9"},
      {:redix, "~> 1.1"},
      
      # Testing and development
      {:excoveralls, "~> 0.18", only: :test},
      {:dialyxir, "~> 1.4", only: [:dev], runtime: false},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:ex_doc, "~> 0.34", only: :dev, runtime: false},
      {:recon, "~> 2.5"},
      {:stream_data, "~> 1.0", only: [:dev, :test]},
      {:benchee, "~> 1.3", only: [:dev]}
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp aliases do
    [
      test: ["test"],
      "compile.profile": ["compile --long-compilation-threshold 2 --warnings-as-errors"],
      "test.phase3": [
        "test test/tiannara/world/property/ --trace",
        "test test/tiannara/world/integration/ --trace",
        "test test/tiannara/world/chaos/ --trace",
        "test test/tiannara/world/epistemic/ --trace"
      ],
      "test.properties": ["test test/tiannara/world/property/ --trace"],
      "validate.phase3": ["compile", "test.phase3"],
      "clean.all": ["clean", "deps.clean --all", "deps.get", "compile"]
    ]
  end
end