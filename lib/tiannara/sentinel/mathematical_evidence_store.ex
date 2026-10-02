defmodule Tiannara.Sentinel.MathematicalEvidenceStore do
  @moduledoc """
  Append-only in-memory Sentinel index for mathematical evidence.

  The store indexes evidence records for retrieval during the runtime session.
  It deliberately does not persist or certify records by itself; durable
  persistence and certification remain governed by the existing audit/registry
  layers.
  """
  use GenServer

  alias Tiannara.Sentinel.MathematicalEvidence

  @name __MODULE__

  def start_link(_opts \\ []), do: GenServer.start_link(__MODULE__, %{}, name: @name)

  def record(kind, artifact, provenance) do
    with {:ok, evidence} <- MathematicalEvidence.build(kind, artifact, provenance) do
      GenServer.call(@name, {:record, evidence})
    end
  end

  def get(id), do: GenServer.call(@name, {:get, id})
  def list, do: GenServer.call(@name, :list)
  def by_kind(kind), do: GenServer.call(@name, {:by_kind, kind})

  @impl true
  def init(_), do: {:ok, %{records: %{}}}

  @impl true
  def handle_call({:record, evidence}, _from, state) do
    if Map.has_key?(state.records, evidence.id) do
      {:reply, {:error, :duplicate_evidence_id}, state}
    else
      {:reply, {:ok, evidence}, %{state | records: Map.put(state.records, evidence.id, evidence)}}
    end
  end

  def handle_call({:get, id}, _from, state), do: {:reply, Map.get(state.records, id), state}
  def handle_call(:list, _from, state), do: {:reply, Map.values(state.records), state}

  def handle_call({:by_kind, kind}, _from, state) do
    {:reply, Enum.filter(Map.values(state.records), &(&1.kind == kind)), state}
  end
end
