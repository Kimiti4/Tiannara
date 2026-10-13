defmodule Tiannara.Reasoning.KnowledgeRepresentation do
  @moduledoc """
  Ontology management, semantic triples, and graph embeddings.

  B11/D-A2: `assert_fact/5` persists a validated research fact into the
  isolated append-only KnowledgeStore with full identity + lineage.
  It does not grant deployment authority; research knowledge stays
  research-only. Missing/invalid inputs fail closed — never success-shaped.
  """

  alias Tiannara.Memory.Artifact
  alias Tiannara.Memory.KnowledgeStore

  @doc """
  Asserts a fact and persists it under the isolated research store.

  `fact` must carry identity (`mission_id`, `hypothesis_id`, `experiment_id`,
  `execution_id`), `lineage`, and `provenance` for D-A2 traceability.
  Returns `{:ok, fact}` on durable append, `{:error, reason}` otherwise.
  """
  @spec assert_fact(term(), term(), term(), number(), map()) ::
          {:ok, map()} | {:error, term()}
  def assert_fact(subject, predicate, object, confidence, fact \\ %{})

  def assert_fact(_subject, _predicate, _object, confidence, _fact)
      when not is_number(confidence) or confidence < 0.0 or confidence > 1.0 do
    {:error, :invalid_confidence}
  end

  def assert_fact(subject, predicate, object, confidence, fact) when is_map(fact) do
    with :ok <- require_identity(fact),
         {:ok, store} <- open_store(),
         :ok <- append_fact(store, subject, predicate, object, confidence, fact) do
      persisted =
        fact
        |> Map.merge(%{
          subject: subject,
          predicate: predicate,
          object: object,
          confidence: confidence,
          lineage: Map.get(fact, :lineage, []),
          persisted_at: DateTime.utc_now()
        })

      {:ok, persisted}
    end
  end

  def assert_fact(_subject, _predicate, _object, _confidence, _fact) do
    {:error, :invalid_fact}
  end

  def query_ontology(_domain, _context), do: {:ok, []}

  defp require_identity(fact) do
    required = [:mission_id, :hypothesis_id, :experiment_id, :execution_id, :lineage, :provenance]

    missing = Enum.reject(required, &Map.has_key?(fact, &1))

    cond do
      missing != [] -> {:error, {:missing_identity, missing}}
      fact.lineage == [] -> {:error, :missing_lineage}
      fact.provenance == nil -> {:error, :missing_provenance}
      true -> :ok
    end
  end

  defp open_store do
    base = Application.get_env(:tiannara, :storage_base, "./data/storage")
    path = Path.join(base, "research_facts")

    case KnowledgeStore.open(path) do
      {:ok, store} ->
        {:ok, store}

      {:error, reason} ->
        {:error, {:knowledge_store_unavailable, reason}}
    end
  end

  defp append_fact(store, subject, predicate, object, confidence, fact) do
    content = %{
      subject: subject,
      predicate: predicate,
      object: object,
      confidence: confidence,
      mission_id: fact.mission_id,
      hypothesis_id: fact.hypothesis_id,
      experiment_id: fact.experiment_id,
      execution_id: fact.execution_id,
      hypothesis: Map.get(fact, :hypothesis),
      params: Map.get(fact, :params),
      evidence: Map.get(fact, :evidence),
      validation: Map.get(fact, :validation),
      provenance: fact.provenance,
      lineage: fact.lineage,
      constitutional:
        Map.get(fact, :constitutional, %{research_only: true, deployment_authority: false})
    }

    artifact =
      Artifact.new(:principle, content,
        evidence: Map.get(fact, :evidence, %{}),
        lineage: fact.lineage,
        confidence: confidence
      )

    case KnowledgeStore.append(store, artifact) do
      :ok -> :ok
      {:error, reason} -> {:error, {:fact_persist_failed, reason}}
    end
  end
end
