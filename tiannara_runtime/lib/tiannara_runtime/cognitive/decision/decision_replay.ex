defmodule TiannaraRuntime.Cognitive.Decision.DecisionReplay do
  defstruct [:id, :session_id, :decision_root, :policy_root, :score_root, :auth_root, :intent_root, :fingerprint, :schema_version, :ontology_version, :created_with_phase, :migration_version]

  @schema_version 1
  @ontology_version 1
  @created_with_phase "18.6"

  def new(fields) do
    id = generate_id(fields)
    struct = %__MODULE__{
      id: id, session_id: fields[:session_id], decision_root: fields[:decision_root],
      policy_root: fields[:policy_root], score_root: fields[:score_root],
      auth_root: fields[:auth_root], intent_root: fields[:intent_root],
      schema_version: @schema_version, ontology_version: @ontology_version,
      created_with_phase: @created_with_phase, migration_version: fields[:migration_version] || 0
    }
    fingerprint = compute_fingerprint(struct)
    {:ok, %{struct | fingerprint: fingerprint}}
  end

  def generate_id(fields) do
    base = "#{fields[:session_id]}_#{:erlang.unique_integer([:positive])}"
    hash = :crypto.hash(:sha256, base) |> Base.encode16(case: :lower) |> String.slice(0, 16)
    "dr_#{hash}"
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

  def record(session) do
    session_id = Map.get(session, :session_id)
    decision_root = :crypto.hash(:sha256, inspect(Map.get(session, :selected, %{}))) |> Base.encode16(case: :lower)
    policy_root = :crypto.hash(:sha256, inspect(Map.get(session, :evaluations, []))) |> Base.encode16(case: :lower)
    score_root = :crypto.hash(:sha256, inspect(Map.get(session, :candidates, []))) |> Base.encode16(case: :lower)
    auth_root = :crypto.hash(:sha256, inspect(Map.get(session, :authorizations, []))) |> Base.encode16(case: :lower)
    intent_root = :crypto.hash(:sha256, "#{session_id}_#{decision_root}") |> Base.encode16(case: :lower)
    replay_id = "drr_#{:erlang.unique_integer([:positive]) |> abs() |> Integer.to_string()}"
    {:ok, %{id: replay_id, session_id: session_id, decision_root: decision_root, policy_root: policy_root, score_root: score_root, auth_root: auth_root, intent_root: intent_root}}
  end

  def verify(replay, session) do
    {:ok, computed} = record(session)
    if Map.get(computed, :decision_root) == Map.get(replay, :decision_root) and
       Map.get(computed, :policy_root) == Map.get(replay, :policy_root) and
       Map.get(computed, :score_root) == Map.get(replay, :score_root) and
       Map.get(computed, :auth_root) == Map.get(replay, :auth_root) and
       Map.get(computed, :intent_root) == Map.get(replay, :intent_root) do
      {:ok, :verified}
    else
      {:error, :hash_mismatch}
    end
  end
end
