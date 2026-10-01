defmodule TiannaraRuntime.Mathematics.ProofObligationGraph do
  @moduledoc "Explicit graph of mathematical proof obligations."
  alias TiannaraRuntime.Mathematics.MathematicalID
  @statuses [:unresolved, :supported, :disproved, :proved, :blocked]

  def new(statement) do
    id = obligation_id(statement)
    %{graph_id: "proof_graph_" <> MathematicalID.from_canonical_map(%{"root" => id}), root: id,
      obligations: %{id => %{id: id, statement: statement, status: :unresolved, dependencies: [], evidence: []}}}
  end

  def add(graph, statement, dependencies \\ []) when is_list(dependencies) do
    id = obligation_id(statement)
    if Enum.all?(dependencies, &Map.has_key?(graph.obligations, &1)) do
      obligation = %{id: id, statement: statement, status: :unresolved, dependencies: Enum.uniq(dependencies), evidence: []}
      {:ok, %{graph | obligations: Map.put(graph.obligations, id, obligation)}}
    else
      {:error, :dependency_not_found}
    end
  end

  def attach_evidence(graph, id, evidence, status) when status in @statuses and is_map(evidence) do
    case Map.get(graph.obligations, id) do
      nil -> {:error, :obligation_not_found}
      obligation -> {:ok, %{graph | obligations: Map.put(graph.obligations, id, %{obligation | status: status, evidence: [evidence | obligation.evidence]})}}
    end
  end

  def prove(graph, id, verifier_evidence) when is_map(verifier_evidence) do
    case Map.get(graph.obligations, id) do
      nil -> {:error, :obligation_not_found}
      %{dependencies: dependencies} = obligation ->
        dependencies_proved = Enum.all?(dependencies, fn dep -> graph.obligations[dep].status == :proved end)
        verified = Map.get(verifier_evidence, :verified, Map.get(verifier_evidence, "verified", false)) == true and
          is_binary(Map.get(verifier_evidence, :verifier_id, Map.get(verifier_evidence, "verifier_id")))
        cond do
          not dependencies_proved -> {:error, :dependencies_not_proved}
          not verified -> {:error, :independent_verification_required}
          true -> {:ok, %{graph | obligations: Map.put(graph.obligations, id, %{obligation | status: :proved, evidence: [verifier_evidence | obligation.evidence]})}}
        end
    end
  end

  def status(graph, id), do: graph.obligations[id] && graph.obligations[id].status
  defp obligation_id(statement), do: "obligation_" <> MathematicalID.from_canonical_map(%{"statement" => statement})
end
