defmodule TiannaraRuntime.Cognitive.Reflection.ReflectionEvidence do
  defstruct [:id, :session_id, :stage, :input_hash, :output_hash, :input, :output, :fingerprint, :schema_version, :ontology_version, :created_with_phase]

  @schema_version 1
  @ontology_version 1
  @created_with_phase "18.7"

  def new(fields) do
    id = generate_id(fields)
    struct = %__MODULE__{
      id: id,
      session_id: Map.get(fields, :session_id),
      stage: Map.get(fields, :stage),
      input_hash: Map.get(fields, :input_hash),
      output_hash: Map.get(fields, :output_hash),
      input: Map.get(fields, :input, %{}),
      output: Map.get(fields, :output, %{}),
      schema_version: @schema_version,
      ontology_version: @ontology_version,
      created_with_phase: @created_with_phase
    }
    fingerprint = compute_fingerprint(struct)
    {:ok, %{struct | fingerprint: fingerprint}}
  end

  def generate_id(fields) do
    base = "#{Map.get(fields, :session_id)}_#{:erlang.unique_integer([:positive])}"
    hash = :crypto.hash(:sha256, base) |> Base.encode16(case: :lower) |> String.slice(0, 16)
    "rev_#{hash}"
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
end
