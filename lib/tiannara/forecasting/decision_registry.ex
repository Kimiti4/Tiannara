defmodule Tiannara.Forecasting.DecisionRegistry do
  @moduledoc """
  D3 decision registry: immutable storage + lineage for `Contracts.Decision`.

  A GenServer backed by an ETS named table (`:efdi_decision_registry`) and
  append-only EventStore lineage.

  Constitutional rules:
    - Decisions are immutable: registering never overwrites; same id → no-op.
    - Each decision id maps to exactly one record.
    - Lineage (`lineage` list) preserves "what was decided and on what basis".
    - Corrections are new versions, never rewrites.
  """

  use GenServer

  alias Tiannara.Forecasting.Decision
  alias Tiannara.Forecasting.Contracts.Decision, as: DecisionRecord

  @table :efdi_decision_registry

  # ------------------------------------------------------------------
  # Client API
  # ------------------------------------------------------------------

  def start_link(opts \\ []) do
    name = Keyword.get(opts, :name, __MODULE__)
    GenServer.start_link(__MODULE__, opts, name: name)
  end

  @spec register(Decision.t()) :: {:ok, Decision.t()} | {:error, term()}
  def register(%DecisionRecord{} = d), do: GenServer.call(__MODULE__, {:register, d})

  @spec get(String.t()) :: {:ok, Decision.t()} | :error
  def get(id) when is_binary(id), do: GenServer.call(__MODULE__, {:get, id})

  @spec all_ids() :: [String.t()]
  def all_ids, do: GenServer.call(__MODULE__, :all_ids)

  @spec count() :: non_neg_integer()
  def count, do: GenServer.call(__MODULE__, :count)

  @spec health() :: map()
  def health, do: GenServer.call(__MODULE__, :health)

  # ------------------------------------------------------------------
  # Server callbacks
  # ------------------------------------------------------------------

  @impl true
  def init(_opts) do
    if :ets.info(@table) != :undefined, do: :ets.delete(@table)
    :ets.new(@table, [:set, :public, :named_table, read_concurrency: true])
    {:ok, %{count: 0, eventstore_degraded: false}}
  end

  @impl true
  def handle_call({:register, d}, _from, state) do
    case Decision.validate(d) do
      {:error, reason} ->
        {:reply, {:error, reason}, state}

      {:ok, d} ->
        case get_by_id(d.id) do
          {:ok, existing} ->
            {:reply, {:ok, existing}, state}

          :error ->
            :ets.insert(@table, {d.id, d})
            maybe_append_event(d)
            {:reply, {:ok, d}, bump(state)}
        end
    end
  end

  @impl true
  def handle_call({:get, id}, _from, state), do: {:reply, get_by_id(id), state}

  @impl true
  def handle_call(:all_ids, _from, state), do: {:reply, all_ids_from_ets(), state}

  @impl true
  def handle_call(:count, _from, state), do: {:reply, state.count, state}

  @impl true
  def handle_call(:health, _from, state) do
    {:reply,
     %{ets_available: :ets.info(@table) != :undefined,
       eventstore_degraded: state.eventstore_degraded}, state}
  end

  # ------------------------------------------------------------------
  # Persistence helpers
  # ------------------------------------------------------------------

  defp get_by_id(id) do
    case :ets.lookup(@table, id) do
      [{_, d}] -> {:ok, d}
      [] -> :error
    end
  end

  defp all_ids_from_ets do
    :ets.foldl(fn entry, acc ->
      case entry do
        {id, %DecisionRecord{}} when is_binary(id) -> [id | acc]
        _ -> acc
      end
    end, [], @table)
  end

  defp bump(state), do: %{state | count: state.count + 1}

  defp maybe_append_event(%DecisionRecord{} = d) do
    try do
      event =
        Tiannara.Executive.Event.new("efdi.decision.registered", %{
          decision_id: d.id,
          question: d.question,
          version: d.decision_version
        })

      Tiannara.Executive.EventStore.append(event)
      :ok
    catch
      _, _ -> :ok
    end
  end
end
