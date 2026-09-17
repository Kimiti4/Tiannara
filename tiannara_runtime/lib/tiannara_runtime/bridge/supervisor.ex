defmodule Tiannara.Bridge.Supervisor do
  @moduledoc """
  Phase 5F.12: OMCE ↔ OLEF Unified Stabilization Bridge Supervisor
  
  Manages the bidirectional thermodynamic coupling between:
  - OMCE (Ontology Memory Compression Engine) → Ω (Omega): ontology density
  - OLEF (Ontological Load Equilibrium Field) → Φ (Phi): load pressure field
  
  Creates a self-stabilizing feedback oscillator where:
    dΩ/dt = compression(Φ) - entropy_loss
    dΦ/dt = diffusion(Ω) - overload_gradient
  """
  
  use Supervisor
  require Logger

  def start_link(arg \\ []) do
    Supervisor.start_link(__MODULE__, arg, name: __MODULE__)
  end

  @impl true
  def init(_arg) do
    children = [
      # Core coupling engine
      {Tiannara.Bridge.OmegaPhiKernel, []},
      
      # Translation layers
      {Tiannara.Bridge.LoadToCompression, []},
      {Tiannara.Bridge.CompressionToLoad, []},
      
      # Safety and stabilization
      {Tiannara.Bridge.StabilityController, []},
      {Tiannara.Bridge.EntropyBalancer, []},
      {Tiannara.Bridge.HarmonicSynchronizer, []}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end

  @doc """
  Trigger a synchronization cycle between OMCE and OLEF states.
  
  ## Parameters
  - omce_state: Current OMCE state map containing ontology metrics
  - olef_state: Current OLEF state map containing load distribution metrics
  
  ## Returns
  {:ok, bridge_state} with updated Ω-Φ equilibrium metrics
  """
  def tick(omce_state, olef_state) do
    GenServer.call(Tiannara.Bridge.OmegaPhiKernel, {:tick, omce_state, olef_state})
  end

  @doc """
  Get current bridge state including stability metrics.
  """
  def get_state do
    GenServer.call(Tiannara.Bridge.OmegaPhiKernel, :get_state)
  end

  @doc """
  Evaluate system stability and trigger corrective actions if needed.
  """
  def evaluate_stability do
    case Tiannara.Bridge.OmegaPhiKernel.get_stability() do
      stability when is_number(stability) ->
        Tiannara.Bridge.StabilityController.evaluate(stability)
      
      _ ->
        {:error, :stability_metric_unavailable}
    end
  end
end
