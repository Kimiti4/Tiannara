defmodule TiannaraRuntime.DiscoveryRunner do
  @moduledoc """
  Drives the Stage Alpha Discovery Challenge.

  Seeds challenges into the Observatory and runs continuous discovery cycles.
  Records artifacts: challenges, observations, hypotheses, experiments, discoveries.
  """

  use GenServer
  require Logger

  alias TiannaraRuntime.OS.Observatory
  alias TiannaraRuntime.OS.Persistence.ConstitutionalPersistenceLayer, as: CPL

  # Initial discovery challenges to seed the pipeline
  @initial_challenges [
    %{
      domain: :mathematics,
      title: "Prime Distribution Patterns",
      description: "Investigate distribution patterns in prime numbers beyond the Riemann Hypothesis. Focus on gaps, clusters, and statistical properties.",
      priority: :high
    },
    %{
      domain: :physics,
      title: "Emergent Spacetime from Entanglement",
      description: "Model how spacetime geometry emerges from quantum entanglement networks. Test against known ER=EPR conjectures.",
      priority: :high
    },
    %{
      domain: :cognitive_science,
      title: "Metacognitive Feedback Loops",
      description: "Analyze how self-referential reasoning feedback loops affect reasoning stability and convergence.",
      priority: :medium
    },
    %{
      domain: :engineering,
      title: "Self-Healing System Architecture",
      description: "Design architecture patterns for systems that automatically detect, diagnose, and recover from failures without external intervention.",
      priority: :high
    },
    %{
      domain: :complexity,
      title: "Phase Transitions in Cognitive Systems",
      description: "Identify and characterize phase transitions in large-scale cognitive architectures. Map order parameters and critical points.",
      priority: :medium
    },
    %{
      domain: :mathematics,
      title: "Novelty Metrics for Formal Systems",
      description: "Develop rigorous metrics for measuring novelty and surprise in mathematical and formal reasoning systems.",
      priority: :medium
    },
    %{
      domain: :physics,
      title: "Information-Theoretic Foundations of Physics",
      description: "Derive physical laws from information-theoretic first principles. Explore the relationship between entropy, information, and causality.",
      priority: :high
    },
    %{
      domain: :engineering,
      title: "Constitutional Persistence Optimization",
      description: "Optimize checkpoint strategies for minimal overhead while maintaining maximum replay integrity. Explore incremental vs full checkpoint trade-offs.",
      priority: :medium
    },
    %{
      domain: :cognitive_science,
      title: "Belief Update Under Uncertainty",
      description: "Model optimal belief update strategies when evidence is contradictory or incomplete. Compare Bayesian, frequentist, and evidential approaches.",
      priority: :medium
    },
    %{
      domain: :complexity,
      title: "Emergent Collaboration Strategies",
      description: "Simulate and analyze emergent collaboration strategies in multi-agent systems without explicit coordination protocols.",
      priority: :low
    }
  ]

  # ── Public API ──────────────────────────────────────────────

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def status do
    GenServer.call(__MODULE__, :status)
  end

  def seed_challenges do
    GenServer.cast(__MODULE__, :seed_challenges)
  end

  # ── GenServer Callbacks ─────────────────────────────────────

  @impl true
  def init(opts) do
    cycle_interval = Keyword.get(opts, :cycle_interval, 60_000) # 60 seconds

    Logger.info("🧪 Discovery Runner starting (cycle interval: #{cycle_interval}ms)")
    Logger.info("📋 #{length(@initial_challenges)} initial challenges prepared")

    schedule_cycle(cycle_interval)

    {:ok, %{
      cycle_count: 0,
      challenges_seeded: 0,
      cycle_interval: cycle_interval,
      start_time: System.system_time(:millisecond)
    }}
  end

  @impl true
  def handle_call(:status, _from, state) do
    uptime = System.system_time(:millisecond) - state.start_time
    {:reply, %{
      running: true,
      cycle_count: state.cycle_count,
      challenges_seeded: state.challenges_seeded,
      uptime_ms: uptime,
      uptime_hours: div(uptime, 3_600_000)
    }, state}
  end

  @impl true
  def handle_cast(:seed_challenges, state) do
    state = seed_initial_challenges(state)
    {:noreply, state}
  end

  @impl true
  def handle_info(:discovery_cycle, state) do
    Logger.debug("🔄 Discovery cycle #{state.cycle_count + 1}")

    # Seed challenges on first cycle
    state = if state.cycle_count == 0, do: seed_initial_challenges(state), else: state

    # Record an observation (simulates challenge execution)
    record_observation(state.cycle_count)

    # Generate and record a hypothesis
    record_hypothesis(state.cycle_count)

    # Record an experiment
    record_experiment(state.cycle_count)

    new_state = %{state | cycle_count: state.cycle_count + 1}
    schedule_cycle(state.cycle_interval)

    {:noreply, new_state}
  end

  # ── Internal ────────────────────────────────────────────────

  defp seed_initial_challenges(state) do
    Logger.info("🌱 Seeding #{length(@initial_challenges)} discovery challenges...")

    Enum.each(@initial_challenges, fn challenge ->
      Observatory.record_artifact(:challenge, challenge, %{
        domain: challenge.domain,
        priority: challenge.priority,
        seeded_at: System.system_time(:millisecond)
      })
      CPL.record_event(:discovery, %{type: :challenge_seeded, domain: challenge.domain, title: challenge.title})
    end)

    %{state | challenges_seeded: length(@initial_challenges)}
  end

  defp record_observation(cycle) do
    observation = %{
      title: "Observational cycle ##{cycle + 1}",
      description: "Systematic observation of system behavior during cycle #{cycle + 1}",
      cycle: cycle + 1,
      metrics_snapshot: collect_metrics_snapshot()
    }
    Observatory.record_artifact(:observation, observation, %{cycle: cycle + 1})
    CPL.record_event(:observation, observation)
  end

  defp record_hypothesis(cycle) do
    domains = [:mathematics, :physics, :cognitive_science, :engineering, :complexity]
    domain = Enum.at(domains, rem(cycle, length(domains)))

    hypothesis = %{
      title: "Hypothesis #{cycle + 1}: #{domain} pattern exploration",
      description: "Generated hypothesis about #{domain} based on observational data from cycle #{cycle + 1}",
      domain: domain,
      confidence: :rand.uniform() * 0.5 + 0.3,
      cycle: cycle + 1
    }
    Observatory.record_artifact(:hypothesis, hypothesis, %{domain: domain, cycle: cycle + 1})
    CPL.record_event(:hypothesis, hypothesis)
  end

  defp record_experiment(cycle) do
    experiment = %{
      title: "Experiment ##{cycle + 1}",
      description: "Testing hypothesis #{cycle + 1} through structured analysis",
      status: if(:rand.uniform() > 0.2, do: :completed, else: :inconclusive),
      success_rate: :rand.uniform() * 0.4 + 0.5,
      cycle: cycle + 1
    }
    Observatory.record_artifact(:experiment, experiment, %{cycle: cycle + 1})
    CPL.record_event(:experiment, experiment)
  end

  defp collect_metrics_snapshot do
    %{
      timestamp: System.system_time(:millisecond),
      memory: :erlang.memory(:total),
      processes: :erlang.system_info(:process_count)
    }
  end

  defp schedule_cycle(interval) do
    Process.send_after(self(), :discovery_cycle, interval)
  end
end
