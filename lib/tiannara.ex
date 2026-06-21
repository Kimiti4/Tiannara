defmodule Tiannara do
  @moduledoc """
  Main Tiannara cosmology runtime module.

  Provides the primary API for interacting with the Tiannara system,
  including ontology management, physics compilation, and stability monitoring.
  """

  alias Tiannara.Core.{Ontology, Causality, Observer}
  alias Tiannara.Stabilization.{HSV, CTL, OCM, TWP, OSL, NDE, RRG, IRD, DFG}
  alias Tiannara.Physics.{OPC, ACF, CCR}

  # Ontology management
  defdelegate create_ontology(concepts, metadata), to: Ontology
  defdelegate compress_ontology(ontology), to: Ontology
  defdelegate merge_ontologies(ontologies), to: Ontology

  # Causality management
  defdelegate validate_causality(causal_graph), to: Causality
  defdelegate repair_timeline(timeline), to: Causality
  defdelegate detect_paradox(causal_structure), to: Causality

  # Observer management
  defdelegate create_observer(config), to: Observer
  defdelegate upgrade_observer(observer, tier), to: Observer
  defdelegate query_observer(observer, query), to: Observer

  # Stabilization layers
  defdelegate archive_singularity(region), to: HSV
  defdelegate stabilize_causality(causal_graph), to: CTL
  defdelegate achieve_consensus(ontologies), to: OCM
  defdelegate prune_timelines(timelines), to: TWP
  defdelegate sandbox_observer(observer), to: OSL
  defdelegate inject_novelty(ecology), to: NDE
  defdelegate govern_recursion(activity), to: RRG
  defdelegate coordinate_interventions(interventions), to: IRD
  defdelegate fold_reality(reality), to: DFG

  # Physics compilation
  defdelegate compile_physics(observer_ontology), to: OPC
  defdelegate validate_conservation(physics), to: ACF
  defdelegate reflect_cosmology(compilation_trace), to: CCR

  # System monitoring
  defdelegate get_system_metrics(), to: Tiannara.Metrics
  defdelegate run_chaos_audit(), to: Tiannara.Audit

  @doc """
  Initialize the Tiannara system with default configuration.
  """
  def start_system(config \\ []) do
    # Initialize high-speed ETS table for Epistemic Shadow-Graph
    :ets.new(:esg_active_shadows, [:set, :public, :named_table, read_concurrency: true])

    # Initialize core systems
    {:ok, _} = Tiannara.Core.Supervisor.start_link(config)
    {:ok, _} = Tiannara.Stabilization.Supervisor.start_link(config)
    {:ok, _} = Tiannara.Physics.Supervisor.start_link(config)
    
    # Initialize NATS connection
    {:ok, _} = Tiannara.Nats.Connection.start_link(config)
    
    Logger.info("Tiannara system initialized")
    :ok
  end

  @doc """
  Shutdown the Tiannara system gracefully.
  """
  def shutdown_system() do
    Logger.info("Initiating Tiannara graceful shutdown")
    
    # Archive current state
    archive_current_state()
    
    # Terminate subsystems
    Supervisor.stop(Tiannara.Core.Supervisor)
    Supervisor.stop(Tiannara.Stabilization.Supervisor)
    Supervisor.stop(Tiannara.Physics.Supervisor)
    
    # Close NATS connection
    Tiannara.Nats.Connection.stop()
    
    Logger.info("Tiannara system shutdown complete")
    :ok
  end

  defp archive_current_state() do
    # Implementation for archiving current system state
    Logger.debug("Archiving current system state")
    # TODO: Implement state archival logic
  end
end