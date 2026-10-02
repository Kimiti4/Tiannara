defmodule Tiannara.Sentinel.MathematicalEvidence do
  @moduledoc """
  Durable-in-process evidence records for mathematical research.

  Sentinel stores the artifact and its provenance; it does not turn storage
  into certification. Proofs, theorem statements, counterexample searches and
  test results retain their exact epistemic status and can be replayed or
  independently audited later.
  """

  use GenServer

  @type record :: %{
          id: String.t(),
          kind: :theorem | :proof | :counterexample_search | :mathematical_test,
          statement: term(),
          artifact: term(),
          evidence: map(),
          status: atom(),
          assumptions: list(),
          provenance: map(),
          created_at: DateTime.t()
        }

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def init(_opts), do: {:ok, %{}}

  @spec store(map()) :: {:ok, record()} | {:error, term()}
  def store(attrs) when is_map(attrs) do
    case validate(attrs) do
      :ok ->
        id = Map.get(attrs, :id) || "math-evidence-#{System.unique_integer([:positive])}"
        record = %{
          id: id,
          kind: attrs.kind,
          statement: attrs.statement,
          artifact: attrs.artifact,
          evidence: Map.get(attrs, :evidence, %{}),
          status: attrs.status,
          assumptions: Map.get(attrs, :assumptions, []),
          provenance: Map.get(attrs, :provenance, %{}),
          created_at: Map.get(attrs, :created_at, DateTime.utc_now())
        }

        GenServer.call(__MODULE__, {:store, record})

      {:error, _} = error ->
        error
    end
  end

  def get(id) when is_binary(id), do: GenServer.call(__MODULE__, {:get, id})
  def list, do: GenServer.call(__MODULE__, :list)

  def handle_call({:store, record}, _from, state) do
    {:reply, {:ok, record}, Map.put(state, record.id, record)}
  end

  def handle_call({:get, id}, _from, state) do
    case Map.fetch(state, id) do
      {:ok, record} -> {:reply, {:ok, record}, state}
      :error -> {:reply, {:error, :not_found}, state}
    end
  end

  def handle_call(:list, _from, state), do: {:reply, Map.values(state), state}

  defp validate(attrs) do
    with :ok <- require(attrs, :kind),
         :ok <- require(attrs, :statement),
         :ok <- require(attrs, :artifact),
         :ok <- require(attrs, :status),
         :ok <- validate_kind(Map.get(attrs, :kind)),
         :ok <- validate_status(Map.get(attrs, :kind), Map.get(attrs, :status)) do
      :ok
    end
  end

  defp require(attrs, key) do
    if Map.has_key?(attrs, key), do: :ok, else: {:error, {:missing_field, key}}
  end

  defp validate_kind(kind) when kind in [:theorem, :proof, :counterexample_search, :mathematical_test], do: :ok
  defp validate_kind(_), do: {:error, :invalid_mathematical_evidence_kind}

  defp validate_status(:proof, status) when status in [:candidate, :proven_under_assumptions, :rejected], do: :ok
  defp validate_status(:theorem, status) when status in [:conjecture, :proven_under_assumptions, :refuted], do: :ok
  defp validate_status(:counterexample_search, status) when status in [:counterexample_found, :no_counterexample_in_domain], do: :ok
  defp validate_status(:mathematical_test, status) when status in [:passed, :failed, :inconclusive], do: :ok
  defp validate_status(_, _), do: {:error, :invalid_mathematical_evidence_status}
end
