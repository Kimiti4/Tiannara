defmodule Tiannara.Domains.Engineering do
  @behaviour Tiannara.Domains.Domain
  alias Tiannara.Foundations.FormalVerification
  alias Tiannara.Math.Probability

  @impl true
  def discover(context), do: {:ok, %{domain: :engineering, discoveries: [], context: context}}

  @impl true
  def evaluate(%{prior: p, likelihood: l, evidence: e}), do: Probability.bayes_update(p, l, e)

  @impl true
  # D-A3 quarantine (2026-09-23): constant verdict with no computation - fabricated domain evidence.
  # Fails closed until a real simulator exists.
  def simulate(_hypothesis, _context), do: {:error, :simulation_unavailable}

  @impl true
  def generate_hypotheses(_context), do: {:ok, []}

  @impl true
  def design_experiments(_hypothesis), do: {:ok, []}

  @impl true
  def validate(experiment) do
    FormalVerification.verify_invariants(experiment.model, [:safety, :reliability, :cost])
  end

  @impl true
  def translate(_hypothesis), do: {:ok, %{engineering_applications: [:production_design]}}

  @impl true
  # A5 quarantine (2026-10-18): previously hardcoded counts and scores
  # presented as measurements (production-readiness scan A5). Keys are
  # preserved for consumers; values are nil with an explicit data_source
  # marker so absent data is never read as a measurement.
  def metrics do
    %{
      active_hypotheses: nil,
      open_experiments: nil,
      discoveries_this_cycle: nil,
      knowledge_growth_rate: nil,
      evidence_quality_score: nil,
      hypotheses_generated: nil,
      experiments_completed: nil,
      data_source: :unavailable
    }
  end
end
