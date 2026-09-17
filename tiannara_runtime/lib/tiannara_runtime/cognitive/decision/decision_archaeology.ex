defmodule TiannaraRuntime.Cognitive.Decision.DecisionArchaeology do
  defstruct [:id, :session_id, :origin, :selection_reason, :rejected_alternatives, :policy_outcomes, :risk_outcomes, :score_breakdown, :auth_reason, :fingerprint, :schema_version, :ontology_version, :created_with_phase, :migration_version]

  @schema_version 1
  @ontology_version 1
  @created_with_phase "18.6"

  def new(fields) do
    id = generate_id(fields)
    struct = %__MODULE__{
      id: id, session_id: fields[:session_id], origin: fields[:origin],
      selection_reason: fields[:selection_reason],
      rejected_alternatives: fields[:rejected_alternatives] || [],
      policy_outcomes: fields[:policy_outcomes] || [],
      risk_outcomes: fields[:risk_outcomes] || [],
      score_breakdown: fields[:score_breakdown],
      auth_reason: fields[:auth_reason],
      schema_version: @schema_version, ontology_version: @ontology_version,
      created_with_phase: @created_with_phase, migration_version: fields[:migration_version] || 0
    }
    fingerprint = compute_fingerprint(struct)
    {:ok, %{struct | fingerprint: fingerprint}}
  end

  def generate_id(fields) do
    base = "#{fields[:session_id]}_#{:erlang.unique_integer([:positive])}"
    hash = :crypto.hash(:sha256, base) |> Base.encode16(case: :lower) |> String.slice(0, 16)
    "da_#{hash}"
  end

  def compute_fingerprint(%__MODULE__{} = s) do
    s |> Map.drop([:id, :fingerprint]) |> Enum.sort_by(fn {k, _} -> k end)
      |> Enum.map(fn {k, v} -> "#{k}:#{inspect(v)}" end) |> Enum.join("|")
      |> then(&:crypto.hash(:sha256, &1)) |> Base.encode16(case: :lower)
  end

  def validate(%__MODULE__{} = s) do
    errors = if is_nil(s.id), do: [{:id, :required}], else: []
    errors = if s.schema_version != @schema_version, do: [{:schema_version, :mismatch} | errors], else: errors
    if errors == [], do: :ok, else: {:error, errors}
  end

  def record(session, origin) do
    selected = Map.get(session, :selected)
    candidates = Map.get(session, :candidates, [])
    selection_reason = case selected do
      nil -> "No candidate selected"
      _ -> "Candidate #{Map.get(selected, :id)} selected"
    end
    rejected = Enum.reject(candidates, fn c -> Map.get(c, :id) == Map.get(selected, :id) end)
    archaeology_id = "darc_#{:erlang.unique_integer([:positive]) |> abs() |> Integer.to_string()}"
    {:ok, %{id: archaeology_id, session_id: Map.get(session, :session_id), origin: origin, selection_reason: selection_reason, rejected_alternatives: Enum.map(rejected, fn c -> Map.get(c, :id) end), policy_outcomes: Map.get(session, :evaluations, []), risk_outcomes: Map.get(session, :risk_assessments, []), score_breakdown: Map.get(selected, :score, %{}), auth_reason: Map.get(session, :authorization_reason)}}
  end

  def explain(archaeology) do
    reason = Map.get(archaeology, :selection_reason, "Unknown reason")
    rejected = Map.get(archaeology, :rejected_alternatives, [])
    policy_count = length(Map.get(archaeology, :policy_outcomes, []))
    risk_count = length(Map.get(archaeology, :risk_outcomes, []))
    rejected_str = case rejected do
      [] -> "no rejected alternatives"
      _ -> "#{length(rejected)} alternative(s) rejected: #{Enum.join(rejected, ", ")}"
    end
    explanation = "Decision: #{reason}. #{rejected_str}. Evaluated #{policy_count} policy outcome(s) and #{risk_count} risk assessment(s)."
    {:ok, explanation}
  end

  def get_lineage(archaeology) do
    {:ok, %{archaeology_id: Map.get(archaeology, :id), session_id: Map.get(archaeology, :session_id), origin: Map.get(archaeology, :origin), selection_reason: Map.get(archaeology, :selection_reason), rejected_alternatives: Map.get(archaeology, :rejected_alternatives)}}
  end
end
