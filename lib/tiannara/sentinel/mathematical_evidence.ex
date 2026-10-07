defmodule Tiannara.Sentinel.MathematicalEvidence do
  @moduledoc """
  Structured evidence record for mathematical research.

  Sentinel stores the evidence artifact and provenance; it does not promote an
  artifact to a theorem merely because it was submitted.

  Stored records are append-only: each one is hashed together with its parent
  lineage by `Tiannara.Sentinel.MathematicalEvidenceArchive`, so later audits
  can detect substitution. Retrieval is session-scoped (in-memory index).
  """

  use GenServer

  @type t :: %{
          id: String.t(),
          kind: atom(),
          status: atom(),
          artifact: map(),
          provenance: map(),
          statement: String.t() | nil,
          evidence: map(),
          assumptions: list(),
          parent_ids: [String.t()],
          hash: String.t() | nil,
          stored_at: DateTime.t()
        }

  @spec start_link(keyword()) :: GenServer.on_start()
  def start_link(opts \\ []), do: GenServer.start_link(__MODULE__, %{}, name: Keyword.get(opts, :name, __MODULE__))

  @doc """
  Stores an evidence record, binding it to its parent lineage hash.
  """
  @spec store(map()) :: {:ok, t()} | {:error, term()}
  def store(attrs) when is_map(attrs), do: GenServer.call(__MODULE__, {:store, attrs})
  def store(_), do: {:error, :invalid_mathematical_evidence}

  @spec get(String.t()) :: {:ok, t()} | {:error, :not_found}
  def get(id), do: GenServer.call(__MODULE__, {:get, id})

  @spec list() :: [t()]
  def list, do: GenServer.call(__MODULE__, :list)

  @spec build(atom(), map(), map()) :: {:ok, map()} | {:error, term()}
  def build(kind, artifact, provenance)
      when is_atom(kind) and is_map(artifact) and is_map(provenance) do
    with :ok <- validate(kind, artifact, provenance) do
      {:ok, %{
        id: "math-evidence-#{System.unique_integer([:positive])}",
        kind: kind,
        status: status(kind, artifact),
        artifact: artifact,
        provenance: provenance,
        stored_at: DateTime.utc_now()
      }}
    end
  end

  def build(_, _, _), do: {:error, :invalid_mathematical_evidence}

  @impl true
  def init(_), do: {:ok, %{records: %{}}}

  @impl true
  def handle_call({:store, attrs}, _from, state) do
    with {:ok, record} <- build_record(attrs),
         {:ok, parents} <- fetch_parents(state.records, record.parent_ids),
         {:ok, archived} <- Tiannara.Sentinel.MathematicalEvidenceArchive.append(record, parents) do
      {:reply, {:ok, archived}, %{state | records: Map.put(state.records, archived.id, archived)}}
    else
      {:error, reason} -> {:reply, {:error, reason}, state}
    end
  end

  def handle_call({:get, id}, _from, state) do
    case Map.fetch(state.records, id) do
      {:ok, record} -> {:reply, {:ok, record}, state}
      :error -> {:reply, {:error, :not_found}, state}
    end
  end

  def handle_call(:list, _from, state), do: {:reply, Map.values(state.records), state}

  defp build_record(attrs) do
    case Enum.find([:kind, :status, :artifact, :provenance], &(not Map.has_key?(attrs, &1))) do
      nil ->
        {:ok, %{
          id: "math-evidence-#{System.unique_integer([:positive])}",
          kind: attrs.kind,
          statement: Map.get(attrs, :statement),
          artifact: attrs.artifact,
          evidence: Map.get(attrs, :evidence, %{}),
          assumptions: Map.get(attrs, :assumptions, []),
          status: attrs.status,
          provenance: attrs.provenance,
          parent_ids: Map.get(attrs, :parent_ids, []),
          stored_at: DateTime.utc_now()
        }}

      key ->
        {:error, {:missing_field, key}}
    end
  end

  defp fetch_parents(records, parent_ids) do
    parents = Enum.map(parent_ids, &Map.get(records, &1))

    if Enum.all?(parents, &is_map/1) do
      {:ok, parents}
    else
      {:error, :unknown_parent_evidence}
    end
  end

  defp validate(:proof_checked, artifact, provenance) do
    with :ok <- required(artifact, [:status, :assumptions, :conclusion, :checked_steps, :kernel]),
         true <- artifact.status == :proven_under_assumptions,
         true <- is_binary(artifact.kernel),
         true <- Map.has_key?(provenance, :proof_steps) do
      :ok
    else
      false -> {:error, :invalid_proof_evidence}
      {:error, _} = error -> error
    end
  end

  defp validate(:counterexample_found, artifact, provenance) do
    with :ok <- required(artifact, [:status, :witness, :tested_cases, :domain]),
         true <- artifact.status == :counterexample_found,
         true <- Map.has_key?(provenance, :search_definition) do
      :ok
    else
      false -> {:error, :invalid_counterexample_evidence}
      {:error, _} = error -> error
    end
  end

  defp validate(:bounded_non_falsification, artifact, provenance) do
    with :ok <- required(artifact, [:status, :tested_cases, :domain, :search_complete]),
         true <- artifact.status == :no_counterexample_in_domain,
         true <- artifact.search_complete == true,
         true <- Map.has_key?(provenance, :search_definition) do
      :ok
    else
      false -> {:error, :invalid_bounded_search_evidence}
      {:error, _} = error -> error
    end
  end

  defp validate(:test_result, artifact, provenance) do
    with :ok <- required(artifact, [:test_id, :status, :result]),
         true <- Map.has_key?(provenance, :execution_id) do
      :ok
    else
      false -> {:error, :execution_provenance_required}
      {:error, _} = error -> error
    end
  end

  defp validate(_, _, _), do: {:error, :unsupported_mathematical_evidence}

  defp required(map, keys) do
    case Enum.find(keys, &(not Map.has_key?(map, &1))) do
      nil -> :ok
      key -> {:error, {:missing_field, key}}
    end
  end

  defp status(:proof_checked, _), do: :proven_under_assumptions
  defp status(:counterexample_found, _), do: :refuted_in_tested_domain
  defp status(:bounded_non_falsification, _), do: :survived_tested_domain
  defp status(:test_result, artifact), do: Map.get(artifact, :status, :observed)
end
