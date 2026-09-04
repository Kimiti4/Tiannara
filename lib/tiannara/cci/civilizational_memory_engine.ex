defmodule Tiannara.CCI.CivilizationalMemoryEngine do
  @moduledoc """
  Civilizational Memory Engine (CME): preserves discoveries, failures, decisions,
  and abandoned pathways as civilizational knowledge.
  Principle: Failure becomes civilization-level knowledge, not deletion.
  """
  use GenServer
  alias Tiannara.CCI.Models.CivilizationalMemoryRecord

  @record_types [:discovery, :failure, :decision, :abandoned_pathway, :successful_strategy, :institutional_evolution]

  def start_link(opts \\ []), do: GenServer.start_link(__MODULE__, %{}, opts)

  def preserve(pid, record_attrs), do: GenServer.call(pid, {:preserve, record_attrs})
  def retrieve(pid, query), do: GenServer.call(pid, {:retrieve, query})
  def find_lessons(pid, domain), do: GenServer.call(pid, {:lessons, domain})
  def get_lineage(pid, record_id), do: GenServer.call(pid, {:lineage, record_id})

  @impl true
  def init(_) do
    {:ok, %{records: %{}, index: %{by_type: %{}, by_domain: %{}, by_lesson: %{}}}}
  end

  @impl true
  def handle_call({:preserve, attrs}, _from, state) do
    unless attrs.type in @record_types do
      {:reply, {:error, :invalid_type}, state}
    else
      record = %CivilizationalMemoryRecord{
        id: UUID.uuid4(),
        type: attrs.type,
        timestamp: DateTime.utc_now(),
        domain: attrs.domain,
        content: attrs.content,
        context: Map.get(attrs, :context, %{}),
        outcome: Map.get(attrs, :outcome),
        lessons_learned: extract_lessons(attrs),
        related_records: Map.get(attrs, :related_records, []),
        preservation_reason: determine_preservation_reason(attrs),
        confidence: Map.get(attrs, :confidence, 0.7),
        reuse_count: 0
      }

      state = put_in(state, [:records, record.id], record)
      state = update_index(state, record)

      Tiannara.RealityGraph.add_node(:civilizational_memory, record)

      {:reply, {:ok, record}, state}
    end
  end

  @impl true
  def handle_call({:retrieve, query}, _from, state) do
    results = case query do
      %{type: type} -> state.records |> Map.values() |> Enum.filter(& &1.type == type)
      %{domain: domain} -> state.records |> Map.values() |> Enum.filter(& &1.domain == domain)
      %{id: id} ->
        case Map.get(state.records, id) do
          nil -> []
          record -> [record]
        end
      _ -> Map.values(state.records)
    end
    {:reply, results, state}
  end

  @impl true
  def handle_call({:lessons, domain}, _from, state) do
    lessons = state.records
    |> Map.values()
    |> Enum.filter(& &1.domain == domain and &1.lessons_learned != [])
    |> Enum.flat_map(& &1.lessons_learned)
    |> Enum.uniq()
    {:reply, lessons, state}
  end

  @impl true
  def handle_call({:lineage, record_id}, _from, state) do
    lineage = trace_lineage(record_id, state.records, [])
    {:reply, lineage, state}
  end

  defp extract_lessons(attrs) do
    case attrs.type do
      :failure -> ["Failure mode: #{attrs.content}", "Avoid: #{Map.get(attrs, :failure_mode, "unknown")}"]
      :discovery -> ["Discovery principle: #{attrs.content}"]
      :decision -> ["Decision rationale: #{Map.get(attrs, :rationale, "unknown")}"]
      _ -> []
    end
  end

  defp determine_preservation_reason(attrs) do
    case attrs.type do
      :failure -> "Prevent recurrence; inform future decisions"
      :discovery -> "Enable knowledge compounding; support future research"
      :abandoned_pathway -> "Prevent redundant exploration; document dead ends"
      :decision -> "Maintain audit trail; support institutional learning"
      _ -> "Civilizational knowledge preservation"
    end
  end

  defp update_index(state, record) do
    state
    |> update_in([:index, :by_type, record.type], fn list -> [record.id | list || []] end)
    |> update_in([:index, :by_domain, record.domain], fn list -> [record.id | list || []] end)
  end

  defp trace_lineage(record_id, records, acc) do
    case Map.get(records, record_id) do
      nil -> acc
      record ->
        new_acc = [record | acc]
        case record.related_records do
          [] -> new_acc
          [parent_id | _] -> trace_lineage(parent_id, records, new_acc)
        end
    end
  end
end
