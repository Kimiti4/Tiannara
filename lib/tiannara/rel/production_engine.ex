defmodule Tiannara.REL.ProductionEngine do
  @moduledoc """
  Generates resources for civilizations based on interaction with reality.
  Replaces infinite consumption with a genuine thermodynamic production loop.
  """

  use GenServer
  require Logger

  alias Tiannara.REL.EconomyEngine
  alias Tiannara.REL.DiscoveryLedger

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc "Reward a civilization for successful predictions (lowers entropy, yields Compute)."
  def reward_prediction(civ_id, accuracy_score) when accuracy_score > 0.0 do
    # Base 10 compute * accuracy
    compute_gain = round(10.0 * accuracy_score)
    if compute_gain > 0 do
      Logger.debug("🧠 [REL-Production] #{civ_id} earned #{compute_gain} Compute from prediction.")
      inject_resources(civ_id, %{compute: compute_gain})
    end
  end

  def reward_prediction(_, _), do: :ok

  @doc "Reward a civilization for new observations (yields Attention)."
  def reward_observation(civ_id, is_novel \\ true) do
    if is_novel do
      Logger.debug("👁️ [REL-Production] #{civ_id} earned 5 Attention from novel observation.")
      inject_resources(civ_id, %{attention: 5})
    end
  end

  @doc "Process passive income from infrastructure discoveries."
  def process_infrastructure_yields(civ_id) do
    GenServer.cast(__MODULE__, {:infrastructure_yields, civ_id})
  end

  @impl true
  def init(_opts) do
    Logger.info("Starting REL Production Engine")
    {:ok, %{}}
  end

  @impl true
  def handle_cast({:infrastructure_yields, civ_id}, state) do
    discoveries = DiscoveryLedger.get_known_discoveries(civ_id)
    
    total_yield = Enum.reduce(discoveries, %{}, fn disc, acc ->
      Map.merge(acc, disc.production_bonus || %{}, fn _k, v1, v2 -> v1 + v2 end)
    end)

    if map_size(total_yield) > 0 do
      inject_resources(civ_id, total_yield)
    end

    {:noreply, state}
  end

  defp inject_resources(civ_id, resources) do
    # EconomyEngine only has `consume`, so we need an `inject` or we just update the budget manually
    # Let's add an `inject` call to EconomyEngine or simulate it if not available.
    Tiannara.REL.EconomyEngine.inject(civ_id, resources)
  end
end
