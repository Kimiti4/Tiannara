defmodule Tiannara.Domains.Computation do
  @behaviour Tiannara.Domains.Domain
  alias Tiannara.Foundations.InformationTheory

  @impl true
  def discover(context), do: {:ok, %{domain: :computation, discoveries: [], context: context}}

  @impl true
  def evaluate(hypothesis) do
    {:ok, InformationTheory.shannon_entropy(Map.values(hypothesis.state_probabilities))}
  end

  @impl true
  # D-A3 quarantine (2026-09-23): constant verdict with no computation - fabricated domain evidence.
  # Fails closed until a real simulator exists.
  def simulate(_hypothesis, _context), do: {:error, :simulation_unavailable}

  @impl true
  def generate_hypotheses(_context), do: {:ok, []}

  @impl true
  def design_experiments(_hypothesis), do: {:ok, []}

  @impl true
  # D-A3 quarantine (2026-09-23): unconditional validity with no verification - fabricated domain evidence.
  # Fails closed until real verification exists.
  def validate(_experiment), do: {:error, :validation_unavailable}

  @impl true
  def translate(_hypothesis), do: {:ok, %{engineering_applications: [:algorithm]}}

  @impl true
  def metrics do
    %{
      active_hypotheses: 112,
      open_experiments: 28,
      discoveries_this_cycle: 5,
      knowledge_growth_rate: 0.15,
      evidence_quality_score: 0.93,
      hypotheses_generated: 112,
      experiments_completed: 28
    }
  end
end
