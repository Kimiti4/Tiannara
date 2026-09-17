defmodule ObservationBus.CIL.Epistemic.KnowledgeConfidenceEngine do
  @moduledoc """
  Assigns and evolves epistemic confidence scores for every knowledge object.

  Confidence factors: evidence count, independent verification, age,
  usage frequency, contradiction score, and stability over time.
  """
  use GenServer

  @table_name :cil_epistemic_confidence

  defstruct [:table, :total_entries]

  @doc false
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    table = :ets.new(@table_name, [:set, :public, :named_table,
                                   write_concurrency: true, read_concurrency: true])
    {:ok, %{table: table, total_entries: 0}}
  end

  @doc "Record or update confidence for a knowledge object."
  @spec record(String.t(), keyword()) :: :ok
  def record(object_id, opts \\ []) do
    GenServer.cast(__MODULE__, {:record, object_id, opts, DateTime.utc_now()})
  end

  @doc "Get confidence for a knowledge object."
  @spec get(String.t()) :: map() | nil
  def get(object_id) do
    case :ets.lookup(@table_name, object_id) do
      [{^object_id, entry}] -> entry
      [] -> nil
    end
  end

  @doc "List all tracked objects."
  @spec list_all() :: [map()]
  def list_all do
    @table_name
    |> :ets.tab2list()
    |> Enum.map(fn {_id, entry} -> entry end)
    |> Enum.sort_by(& &1.confidence, :desc)
  end

  @doc "Get epistemic summary statistics."
  @spec summary() :: map()
  def summary do
    GenServer.call(__MODULE__, :summary)
  end

  @impl true
  def handle_cast({:record, object_id, opts, now}, state) do
    existing = get(object_id)

    evidence_count = Keyword.get(opts, :evidence_count, (existing && existing.evidence_count) || 1)
    verifications = Keyword.get(opts, :verifications, (existing && existing.verifications) || 0)
    contradictions = Keyword.get(opts, :contradictions, (existing && existing.contradictions) || 0)
    usage = Keyword.get(opts, :usage, (existing && existing.usage) || 0)
    category = Keyword.get(opts, :category, (existing && existing.category) || "unknown")

    age_days = if existing do
      DateTime.diff(now, existing.recorded_at, :day) |> abs()
    else
      0
    end

    stability = compute_stability(existing, contradictions, usage, age_days)
    confidence = compute_confidence(evidence_count, verifications, contradictions, usage, age_days, stability)

    entry = %{
      object_id: object_id,
      category: category,
      confidence: confidence,
      evidence_count: evidence_count,
      verifications: verifications,
      contradictions: contradictions,
      usage: usage,
      stability: stability,
      age_days: age_days,
      recorded_at: (existing && existing.recorded_at) || now,
      updated_at: now
    }

    :ets.insert(@table_name, {object_id, entry})
    {:noreply, %{state | total_entries: state.total_entries + (if existing, do: 0, else: 1)}}
  end

  @impl true
  def handle_call(:summary, _from, state) do
    all = :ets.tab2list(@table_name) |> Enum.map(fn {_, e} -> e end)
    confidences = Enum.map(all, & &1.confidence)

    {:reply, %{
      total_objects: length(all),
      mean_confidence: if(length(confidences) > 0, do: Enum.sum(confidences) / length(confidences), else: 0.0),
      min_confidence: if(length(confidences) > 0, do: Enum.min(confidences), else: 0.0),
      max_confidence: if(length(confidences) > 0, do: Enum.max(confidences), else: 0.0),
      categories: Enum.group_by(all, & &1.category) |> Enum.map(fn {k, v} -> {k, length(v)} end) |> Map.new()
    }, state}
  end

  defp compute_stability(nil, _contradictions, _usage, _age), do: 0.5
  defp compute_stability(prev, contradictions, usage, age_days) do
    prev_stab = prev.stability
    delta = (contradictions - (prev.contradictions || 0)) * 0.1 + (usage - (prev.usage || 0)) * 0.01
    max(0.0, min(1.0, prev_stab - delta + age_days * 0.001))
  end

  defp compute_confidence(ev_cnt, verifs, contradictions, usage, age_days, stability) do
    ev = min(1.0, ev_cnt / 20.0) * 0.25
    vf = min(1.0, verifs / 5.0) * 0.20
    ct = max(0.0, 1.0 - contradictions / 10.0) * 0.20
    us = min(1.0, usage / 100.0) * 0.10
    ag = max(0.0, 1.0 - age_days / 365.0) * 0.05
    st = stability * 0.20
    min(1.0, ev + vf + ct + us + ag + st)
  end
end
