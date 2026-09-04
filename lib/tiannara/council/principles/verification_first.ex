defmodule Tiannara.Council.Principles.VerificationFirst do
  @moduledoc """
  Principle: Verification First.
  "Capability must never outpace verification."
  """
  @behaviour Tiannara.Council.ConstitutionalPrinciple

  @impl true
  def id, do: :verification_first

  @impl true
  def name, do: "Verification First"

  @impl true
  def version, do: "1.0.0"

  @impl true
  def weight, do: 1.0

  @impl true
  def evaluate(decision_type, payload, _context) do
    validated = Map.get(payload, :validated, false)
    stress_tested = Map.get(payload, :stress_tested, false)

    {verdict, reasoning, evidence} =
      cond do
        decision_type in [:deploy, :activate, :scale] and not validated ->
          {:violated, "Action attempts to deploy without validation.",
           [%{type: :validation_status, value: validated}]}

        decision_type in [:deploy, :activate] and validated and stress_tested ->
          {:strengthened, "Fully validated and stress-tested prior to deployment.",
           [%{type: :validation_status, value: validated}, %{type: :stress_tested, value: stress_tested}]}

        true ->
          {:neutral, "Does not trigger deployment-level verification.",
           [%{type: :validation_status, value: validated}]}
      end

    %{
      principle_id: id(),
      principle_name: name(),
      version: version(),
      verdict: verdict,
      reasoning: reasoning,
      evidence: evidence,
      weight: weight()
    }
  end
end
