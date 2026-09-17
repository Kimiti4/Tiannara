defmodule TiannaraRuntime.CausalDiscovery.CausalArchaeology do
  @moduledoc """
  Phase 17.3 — CausalArchaeology: full lineage tracking for causal discovery decisions.
  Content-addressed ID prefix: ca_
  """
  alias TiannaraRuntime.CausalDiscovery.ArchaeologyEntry

  @enforce_keys [:model_id, :entries]
  defstruct [:archaeology_id, :model_id, :entries, :fingerprint]

  @type t :: %__MODULE__{
    archaeology_id: String.t(),
    model_id: String.t(),
    entries: [ArchaeologyEntry.t()],
    fingerprint: String.t() | nil
  }

  @spec new(keyword()) :: {:ok, t()} | {:error, String.t()}
  def new(opts \\ []) do
    a = %__MODULE__{
      archaeology_id: Keyword.get(opts, :archaeology_id),
      model_id: Keyword.get(opts, :model_id),
      entries: Keyword.get(opts, :entries, []),
      fingerprint: Keyword.get(opts, :fingerprint)
    }
    with {:ok, a} <- validate(a),
         do: {:ok, ensure_id(a)}
  end

  @spec validate(t()) :: {:ok, t()} | {:error, String.t()}
  def validate(%__MODULE__{model_id: m}) when is_nil(m) or m == "",
    do: {:error, "CausalArchaeology model_id must not be empty"}
  def validate(%__MODULE__{entries: e}) when not is_list(e),
    do: {:error, "CausalArchaeology entries must be a list"}
  def validate(%__MODULE__{} = a), do: {:ok, a}
  def validate(_), do: {:error, "invalid CausalArchaeology"}

  @spec canonicalize(t()) :: map()
  def canonicalize(%__MODULE__{} = a) do
    Map.from_struct(a)
    |> Map.delete(:__struct__)
    |> Enum.map(fn {k, v} -> {to_string(k), canonical_value(v)} end)
    |> Enum.sort_by(fn {k, _} -> k end)
    |> Enum.into(%{})
  end

  defp canonical_value(v) when is_list(v), do: Enum.map(v, fn
    %{__struct__: _} = e -> ArchaeologyEntry.canonicalize(e)
    other -> other
  end)
  defp canonical_value(v), do: v

  @spec compute_id(t()) :: String.t()
  def compute_id(%__MODULE__{} = a) do
    fingerprints = a.entries |> Enum.map(& &1.entry_id) |> Enum.sort() |> Enum.join("|")
    "ca_" <> (:crypto.hash(:sha256, fingerprints) |> Base.encode16(case: :lower))
  end

  defp ensure_id(%__MODULE__{archaeology_id: nil} = a), do: %{a | archaeology_id: compute_id(a)}
  defp ensure_id(%__MODULE__{} = a), do: a

  # --- API Functions ---

  @registry_table :causal_archaeology_registry

  @spec record_entry(atom(), [String.t()], [String.t()], [String.t()], [String.t()], keyword()) :: {:ok, ArchaeologyEntry.t()}
  def record_entry(stage, input, output, alternatives, evidence_roots, opts \\ []) do
    desc = Keyword.get(opts, :description, "Stage: #{stage}")

    {:ok, entry} =
      ArchaeologyEntry.new(
        stage: stage,
        description: desc,
        input_fingerprints: input,
        output_fingerprints: output,
        alternatives: alternatives,
        evidence_roots: evidence_roots,
        metadata: Keyword.get(opts, :metadata, %{})
      )

    fingerprint = Keyword.get(opts, :graph_fingerprint)
    if fingerprint do
      table = ensure_registry_table()
      entries = case :ets.lookup(table, fingerprint) do
        [{^fingerprint, existing}] -> existing ++ [entry]
        _ -> [entry]
      end
      :ets.insert(table, {fingerprint, entries})
    end

    {:ok, entry}
  end

  @spec record_edge_origin(String.t(), term(), float(), map()) :: {:ok, ArchaeologyEntry.t()}
  def record_edge_origin(edge_id, independence_result, score, context) do
    {:ok, entry} =
      ArchaeologyEntry.new(
        stage: :edge_derivation,
        description: "Edge #{edge_id} derived from independence test",
        output_fingerprints: [edge_id],
        metadata: Map.merge(context, %{independence_result: inspect(independence_result), score: score})
      )

    table = ensure_registry_table()
    edge_key = {:edge, edge_id}

    entries = case :ets.lookup(table, edge_key) do
      [{^edge_key, existing}] -> existing ++ [entry]
      _ -> [entry]
    end

    :ets.insert(table, {edge_key, entries})
    {:ok, entry}
  end

  @spec get_lineage(String.t()) :: {:ok, [ArchaeologyEntry.t()]} | {:error, :not_found}
  def get_lineage(graph_fingerprint) do
    table = ensure_registry_table()
    case :ets.lookup(table, graph_fingerprint) do
      [{^graph_fingerprint, entries}] -> {:ok, entries}
      _ -> {:error, :not_found}
    end
  end

  @spec get_edge_history(String.t()) :: {:ok, [ArchaeologyEntry.t()]} | {:error, :not_found}
  def get_edge_history(edge_id) do
    table = ensure_registry_table()
    edge_key = {:edge, edge_id}

    case :ets.lookup(table, edge_key) do
      [{^edge_key, entries}] ->
        {:ok, entries}
      _ ->
        all_entries = :ets.tab2list(table) |> Enum.flat_map(fn {_, ents} -> ents end)
        matching = Enum.filter(all_entries, fn e -> edge_id in e.output_fingerprints end)
        case matching do
          [] -> {:error, :not_found}
          _ -> {:ok, matching}
        end
    end
  end

  @spec get_rejected_alternatives(String.t()) :: {:ok, [String.t()]}
  def get_rejected_alternatives(graph_fingerprint) do
    table = ensure_registry_table()
    case :ets.lookup(table, graph_fingerprint) do
      [{^graph_fingerprint, entries}] ->
        alternatives = entries |> Enum.flat_map(& &1.alternatives) |> Enum.uniq()
        {:ok, alternatives}
      _ ->
        {:ok, []}
    end
  end

  @spec reconstruct_graph_history(String.t(), any(), any()) :: {:ok, t()}
  def reconstruct_graph_history(graph_fingerprint, _evidence_set, _config) do
    table = ensure_registry_table()
    entries = case :ets.lookup(table, graph_fingerprint) do
      [{^graph_fingerprint, es}] -> es
      _ -> []
    end
    {:ok, archaeology} = new(model_id: graph_fingerprint, entries: entries)
    {:ok, archaeology}
  end

  @spec archaeology_fingerprint(t()) :: String.t()
  def archaeology_fingerprint(%__MODULE__{} = archaeology) do
    entry_fps = archaeology.entries |> Enum.map(& &1.entry_id) |> Enum.sort() |> Enum.join("|")
    "caf_" <> (:crypto.hash(:sha256, entry_fps) |> Base.encode16(case: :lower))
  end

  defp ensure_registry_table do
    case :ets.info(@registry_table) do
      :undefined -> :ets.new(@registry_table, [:set, :public, :named_table])
      _ -> @registry_table
    end
  end
end
