defmodule Tiannara.Discovery.PipelineTelemetry do
  @moduledoc """
  Stage 1 of the instrument-first build: a live audit of the discovery chain.

  Every stage declares reader attempts against the REAL module surface,
  verified by `pipeline_telemetry_contract_test.exs` (a reader may only
  resolve against keys the source module actually emits). A stage whose
  readers cannot resolve a counter is reported `:uninstrumented` — that
  grey cell IS the diagnostic the checklist script and the dashboard act
  on. Counters that exist go green with their real values.

  Two stages are deliberately NOT raw counter reads:

    * `knowledge_integration` reports EARNED knowledge = total world
      entities MINUS epistemic-seed inputs (seeds are inputs, never
      integrations); the snapshot carries `seeded_inputs` beside it.

  Statuses:
    * `:growing`     — value increased since the last sample
    * `:flat`        — value unchanged since the last sample
    * `:regressed`   — value decreased since the last sample
    * `:present`     — value present, no comparable previous sample yet
    * `:uninstrumented` — no reader resolved a counter (the diagnostic)
    * `:error`       — a reader raised

  First stall: the first `:flat`/`:uninstrumented`/`:error` stage after a
  `:growing`/`:present` predecessor; any `:uninstrumented` stage is itself a
  stall regardless of predecessor.
  """

  use GenServer
  require Logger

  alias Tiannara.Discovery.{DiscoveryEngine, DiscoveryScheduler}
  alias Tiannara.World.{UnifiedRealityGraph, UnifiedWorldModel}

  @sample_interval :timer.minutes(1)
  @history_cap 500

  @stage_order [
    :observation,
    :unknown_detection,
    :hypothesis,
    :experiment_schedule,
    :experiment_execute,
    :evidence,
    :knowledge_integration,
    :graph_growth,
    :discovery_promotion
  ]

  @readers %{
    observation: [
      {:call, {UnifiedWorldModel, :stats, 0}, [:entity_count]}
    ],
    unknown_detection: [
      {:call, {DiscoveryScheduler, :get_stats, 0}, [:total_gaps_detected]}
    ],
    hypothesis: [
      {:call, {DiscoveryScheduler, :get_stats, 0}, [:total_hypotheses_generated]}
    ],
    experiment_schedule: [
      {:call, {DiscoveryScheduler, :get_stats, 0}, [:total_experiments_planned]}
    ],
    experiment_execute: [
      {:call, {DiscoveryScheduler, :get_stats, 0}, [:total_experiments_executed]}
    ],
    evidence: [
      {:call, {DiscoveryEngine, :get_stats, 0}, [:evidence_routed]}
    ],
    knowledge_integration: [:earned_knowledge],
    graph_growth: [
      {:call, {UnifiedRealityGraph, :stats, 0}, [:relationship_count]}
    ],
    discovery_promotion: [
      {:call, {UnifiedWorldModel, :stats, 0}, [:entity_type_distribution, :scientific_entity]}
    ]
  }

  def start_link(opts),
    do: GenServer.start_link(__MODULE__, %{}, Keyword.merge([name: __MODULE__], opts))

  @doc "The discovery pipeline stages, in order."
  def stages, do: @stage_order

  @doc "Live snapshot: current value and status per stage, plus the first stall."
  def snapshot, do: GenServer.call(__MODULE__, :snapshot)

  @doc "The first stage that stopped moving, or nil."
  def first_stall, do: GenServer.call(__MODULE__, :first_stall)

  @doc "Capped status history, most recent last."
  def history, do: GenServer.call(__MODULE__, :history)

  @doc "The stage → reader table. The contract test pins every reader to a key the source module actually emits."
  def readers, do: @readers

  @impl true
  def init(_opts) do
    Process.send_after(self(), :sample, @sample_interval)
    {:ok, %{last_values: %{}, history: [], sample_count: 0, started_at: DateTime.utc_now()}}
  end

  @impl true
  def handle_call(:snapshot, _from, state) do
    {snap, state} = build_snapshot(state)
    {:reply, snap, state}
  end

  def handle_call(:first_stall, _from, state) do
    {snap, state} = build_snapshot(state)
    {:reply, snap.first_stall, state}
  end

  def handle_call(:history, _from, state), do: {:reply, state.history, state}

  @impl true
  def handle_info(:sample, state) do
    {_snap, state} = build_snapshot(state)
    Process.send_after(self(), :sample, @sample_interval)
    {:noreply, state}
  end

  defp build_snapshot(state) do
    {stage_results, last_values} =
      Enum.reduce(@stage_order, {%{}, %{}}, fn stage, {acc, lv} ->
        {value, status} = read_stage(stage, Map.get(state.last_values, stage))
        {Map.put(acc, stage, %{status: status, value: value}), Map.put(lv, stage, value)}
      end)

    statuses =
      Enum.map(@stage_order, fn stage ->
        %{stage: stage, status: stage_results[stage].status, value: stage_results[stage].value}
      end)

    stall = find_first_stall(statuses)
    sample_count = state.sample_count + 1

    history =
      (state.history ++
         [
           %{
             sampled_at: DateTime.utc_now(),
             sample_count: sample_count,
             statuses: Map.new(@stage_order, fn stage -> {stage, stage_results[stage].status} end)
           }
         ])
      |> Enum.take(-@history_cap)

    snap = %{
      stages: stage_results,
      first_stall: stall,
      seeded_inputs: seeded_entity_count(),
      uninstrumented:
        Enum.filter(statuses, &(&1.status == :uninstrumented)) |> Enum.map(& &1.stage),
      sample_count: sample_count,
      sampled_at: DateTime.utc_now(),
      started_at: state.started_at
    }

    {snap, %{state | last_values: last_values, history: history, sample_count: sample_count}}
  end

  defp read_stage(stage, prev) do
    case resolve_readers(Map.fetch!(@readers, stage)) do
      :uninstrumented -> {:uninstrumented, :uninstrumented}
      {:error, reason} -> {{:error, reason}, {:error, reason}}
      value -> {value, classify(value, prev)}
    end
  end

  defp classify(value, prev) when is_number(value) do
    cond do
      prev == nil -> :present
      value > prev -> :growing
      value < prev -> :regressed
      value == prev -> :flat
    end
  end

  defp read_knowledge do
    total =
      read_attempt({:call, {UnifiedWorldModel, :stats, 0}, [:entity_count]})

    case {total, seeded_entity_count()} do
      {:uninstrumented, _} -> :uninstrumented
      {_, nil} -> :uninstrumented
      {total, seeded} -> max(0, total - seeded)
    end
  end

  @doc """
  Counts entities whose provenance origin is `:epistemic_seed`. These are
  INPUTS injected by the seeder, never integrations performed by the
  pipeline; the earned-vs-seeded split keeps input and output side by side.
  """
  defp seeded_entity_count do
    if Process.whereis(UnifiedRealityGraph) != nil do
      case UnifiedRealityGraph.query_entities(
             predicate: fn e -> get_in(e, [:provenance, :origin]) == :epistemic_seed end,
             limit: 100_000
           ) do
        {:ok, ids} -> length(ids)
        _ -> nil
      end
    else
      nil
    end
  rescue
    _ -> nil
  end

  defp resolve_readers([:earned_knowledge]), do: read_knowledge()

  defp resolve_readers(attempts) do
    Enum.reduce_while(attempts, :uninstrumented, fn attempt, _acc ->
      case safe_read(attempt) do
        :uninstrumented -> {:cont, :uninstrumented}
        {:error, _} = err -> {:halt, err}
        value -> {:halt, value}
      end
    end)
  end

  defp safe_read(attempt) do
    read_attempt(attempt)
  rescue
    e -> {:error, {:reader_raised, Exception.message(e)}}
  end

  defp read_attempt({:call, {mod, fun, 0}, path}) do
    if Process.whereis(mod) != nil and function_exported?(mod, fun, 0) do
      apply(mod, fun, []) |> extract(path)
    else
      :uninstrumented
    end
  end

  defp read_attempt({:call, {mod, fun, 1}, [arg]}) do
    if Process.whereis(mod) != nil and function_exported?(mod, fun, 1) do
      case apply(mod, fun, [arg]) do
        {:ok, value} -> value
        value -> value
      end
    else
      :uninstrumented
    end
  end

  defp extract(value, []), do: value

  defp extract(%{} = map, [key | rest]) do
    if Map.has_key?(map, key) do
      extract(Map.get(map, key), rest)
    else
      :uninstrumented
    end
  end

  defp extract(_other, _path), do: :uninstrumented

  defp find_first_stall(statuses) do
    statuses
    |> Enum.with_index()
    |> Enum.find(fn {entry, idx} ->
      case entry.status do
        :uninstrumented ->
          true

        status when status in [:flat, :error] ->
          idx > 0 and Enum.at(statuses, idx - 1).status in [:growing, :present]

        _ ->
          false
      end
    end)
    |> case do
      nil -> nil
      {entry, _idx} -> %{stage: entry.stage, status: entry.status}
    end
  end
end
