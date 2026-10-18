defmodule Tiannara.Domains.Governance do
  @behaviour Tiannara.Domains.Domain
  alias Tiannara.Foundations.InformationTheory

  @impl true
  def discover(context), do: {:ok, %{domain: :governance, discoveries: [], context: context}}

  @impl true
  # A5 quarantine (2026-10-18): constant verdict with no computation -
  # fabricated domain evidence (production-readiness scan A5).
  # Fails closed until a real evaluator exists.
  def evaluate(_hypothesis), do: {:error, :evaluation_unavailable}

  @impl true
  # D-A3 quarantine (2026-09-23): constant verdict with no computation - fabricated domain evidence.
  # Fails closed until a real simulator exists.
  def simulate(_hypothesis, _context), do: {:error, :simulation_unavailable}

  @impl true
  def generate_hypotheses(_context), do: {:ok, []}

  @impl true
  def design_experiments(_hypothesis), do: {:ok, []}

  @impl true
  # D-A3 quarantine (2026-09-23): fabricated constitutional_alignment: 0.94 with no verification.
  # Fails closed until real verification exists.
  def validate(_experiment), do: {:error, :validation_unavailable}

  @impl true
  def translate(_hypothesis), do: {:ok, %{engineering_applications: [:policy_framework]}}

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
