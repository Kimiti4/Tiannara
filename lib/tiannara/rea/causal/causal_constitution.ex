defmodule Tiannara.REA.Causal.CausalConstitution do
  @moduledoc """
  Four-tier classification of causal channels based on criticality analysis.

  Tiers:
    - :constitutional  — Irreplaceable AND critical. Cannot be deleted.
                         Parametric mutations bounded tightly around optimal.
    - :structural      — Critical but replaceable. Cannot be deleted.
                         Parametric mutations bounded loosely.
                         Can be superseded by a proven replacement pathway.
    - :adaptive        — Moderately critical and replaceable.
                         Can be disabled, rewired, or deleted by MetaGenomes.
    - :experimental    — Low criticality or fully replaceable.
                         Fully evolvable.

  The constitution is not permanent: Structural channels can be
  *superseded* if a MetaGenome-proposed replacement demonstrates
  sustained superiority over multiple evaluation windows.
  """

  use GenServer

  @type tier :: :constitutional | :structural | :adaptive | :experimental
  @type channel_bounds :: %{
    channel_id: binary(),
    channel_name: atom(),
    tier: tier(),
    min_weight: float(),
    max_weight: float(),
    min_delay: integer(),
    max_delay: integer(),
    optimal_weight: float(),
    optimal_delay: integer(),
    criticality_score: float(),
    bottleneck: float(),
    replaceability: float(),
    elasticity: float(),
    can_be_deleted: boolean(),
    supersession_window: non_neg_integer()
  }

  def start_link(opts \\ []), do: GenServer.start_link(__MODULE__, opts, name: __MODULE__)

  @spec enact([map()]) :: :ok
  def enact(profiles), do: GenServer.call(__MODULE__, {:enact, profiles})

  @spec tier(binary()) :: tier() | nil
  def tier(ch_id), do: GenServer.call(__MODULE__, {:tier, ch_id})

  @spec get_bounds(binary()) :: channel_bounds() | nil
  def get_bounds(ch_id), do: GenServer.call(__MODULE__, {:get_bounds, ch_id})

  @spec validate_mutation(binary(), keyword()) :: :ok | {:error, atom()}
  def validate_mutation(ch_id, changes), do: GenServer.call(__MODULE__, {:validate, ch_id, changes})

  @spec can_be_deleted?(binary()) :: boolean()
  def can_be_deleted?(ch_id), do: GenServer.call(__MODULE__, {:can_delete, ch_id})

  @spec all() :: [channel_bounds()]
  def all, do: GenServer.call(__MODULE__, :all)

  @spec by_tier(tier()) :: [channel_bounds()]
  def by_tier(tier), do: GenServer.call(__MODULE__, {:by_tier, tier})

  @spec register_supersession(binary(), binary()) :: :ok
  def register_supersession(original_id, replacement_id),
    do: GenServer.call(__MODULE__, {:register_supersession, original_id, replacement_id})

  @spec supersede(binary()) :: :ok | {:error, atom()}
  def supersede(ch_id), do: GenServer.call(__MODULE__, {:supersede, ch_id})

  # --- Server ---

  @impl true
  def init(_), do: {:ok, %{constitution: %{}, supersessions: %{}}}

  @impl true
  def handle_call({:enact, profiles}, _from, state) do
    constitution =
      profiles
      |> Enum.map(fn p -> {p.channel_id, build_bounds(p)} end)
      |> Map.new()
    {:reply, :ok, %{state | constitution: constitution}}
  end

  @impl true
  def handle_call({:tier, ch_id}, _from, state),
    do: {:reply, state.constitution[ch_id] && state.constitution[ch_id].tier, state}

  @impl true
  def handle_call({:get_bounds, ch_id}, _from, state),
    do: {:reply, Map.get(state.constitution, ch_id), state}

  @impl true
  def handle_call({:can_delete, ch_id}, _from, state),
    do: {:reply, state.constitution[ch_id] && state.constitution[ch_id].can_be_deleted, state}

  @impl true
  def handle_call(:all, _from, state),
    do: {:reply, Map.values(state.constitution), state}

  @impl true
  def handle_call({:by_tier, tier}, _from, state) do
    result = state.constitution |> Map.values() |> Enum.filter(&(&1.tier == tier))
    {:reply, result, state}
  end

  @impl true
  def handle_call({:validate, ch_id, changes}, _from, state) do
    case Map.get(state.constitution, ch_id) do
      nil -> {:reply, :ok, state}
      bounds ->
        cond do
          Keyword.has_key?(changes, :delete) && not bounds.can_be_deleted ->
            {:reply, {:error, :channel_is_protected}, state}
          changes[:weight] && (changes[:weight] < bounds.min_weight or changes[:weight] > bounds.max_weight) ->
            {:reply, {:error, :weight_out_of_bounds}, state}
          changes[:delay] && (changes[:delay] < bounds.min_delay or changes[:delay] > bounds.max_delay) ->
            {:reply, {:error, :delay_out_of_bounds}, state}
          true -> {:reply, :ok, state}
        end
    end
  end

  @impl true
  def handle_call({:register_supersession, orig_id, repl_id}, _from, state) do
    new_ss = Map.update(state.supersessions, orig_id, %{replacement: repl_id, wins: 0, window: 0},
      fn s -> %{s | replacement: repl_id} end)
    {:reply, :ok, %{state | supersessions: new_ss}}
  end

  @impl true
  def handle_call({:supersede, ch_id}, _from, state) do
    case {Map.get(state.constitution, ch_id), Map.get(state.supersessions, ch_id)} do
      {%{tier: :structural} = bounds, %{wins: wins}} when wins >= bounds.supersession_window ->
        new_bounds = %{bounds | tier: :adaptive, can_be_deleted: true}
        new_constitution = Map.put(state.constitution, ch_id, new_bounds)
        new_ss = Map.delete(state.supersessions, ch_id)
        {:reply, :ok, %{state | constitution: new_constitution, supersessions: new_ss}}
      {nil, _} -> {:reply, {:error, :not_in_constitution}, state}
      {%{tier: :constitutional}, _} -> {:reply, {:error, :constitutional_cannot_be_superseded}, state}
      {%{tier: tier}, _} when tier in [:adaptive, :experimental] ->
        {:reply, {:error, :already_evolvable}, state}
      {_, %{wins: wins}} ->
        {:reply, {:error, {:insufficient_evidence, wins}}, state}
    end
  end

  defp build_bounds(p) do
    {tier, bounds_mult, can_delete, supersession} = case p.classification do
      :constitutional -> {:constitutional, 0.25, false, 0}
      :structural     -> {:structural,     0.50, false, 50}
      :adaptive       -> {:adaptive,       1.00, true,  0}
      :experimental   -> {:experimental,   2.00, true,  0}
      # default mappings if exact match not found
      _               -> {:experimental,   2.00, true,  0}
    end

    elasticity = Map.get(p, :evolutionary_elasticity, 0.5)

    %{
      channel_id: p.channel_id,
      channel_name: p.channel_name,
      tier: tier,
      min_weight: p.optimal_weight * (1 - bounds_mult),
      max_weight: p.optimal_weight * (1 + bounds_mult),
      min_delay: max(0, p.optimal_delay - trunc(bounds_mult * 2)),
      max_delay: p.optimal_delay + trunc(bounds_mult * 2),
      optimal_weight: p.optimal_weight,
      optimal_delay: p.optimal_delay,
      criticality_score: p.criticality_score,
      bottleneck: Map.get(p, :bottleneck, 0.0),
      replaceability: Map.get(p, :replaceability, 0.0),
      elasticity: elasticity,
      can_be_deleted: can_delete,
      supersession_window: supersession
    }
  end
end
