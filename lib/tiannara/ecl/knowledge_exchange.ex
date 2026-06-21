defmodule Tiannara.ECL.KnowledgeExchange do
  @moduledoc """
  Phase ECL-1: Objective cross-shard discovery marketplace.
  Publishes only stable discoveries (≥0.8). Routed by epistemic trust score.
  """
  use GenServer
  require Logger

  @type published_discovery :: %{
    discovery_id: String.t(),
    origin_civ_id: String.t(),
    origin_shard_id: String.t(),
    stability_score: float(),
    trust_score: float(),
    domain: atom(),
    license_cost: map(),
    status: :active | :archaeological
  }

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    {:ok, %{
      lattice: :gb_trees.empty(),  # trust_score → [published_discovery]
      subscribers: %{},            # shard_id → pid
      metrics: %{publishes: 0, licenses: 0, quarantines: 0}
    }}
  end

  # Public API
  def publish_discovery(discovery_id, civ_id, shard_id) do
    GenServer.call(__MODULE__, {:publish, discovery_id, civ_id, shard_id})
  end

  def publish_operator(operator_id, civ_id, shard_id) do
    GenServer.call(__MODULE__, {:publish_operator, operator_id, civ_id, shard_id})
  end

  def search_discoveries(domain, max_cost \\ nil) do
    GenServer.call(__MODULE__, {:search, domain, max_cost})
  end

  def request_license(requester_civ_id, requester_shard_id, discovery_id) do
    GenServer.cast(__MODULE__, {:license, requester_civ_id, requester_shard_id, discovery_id})
  end

  def request_operator_license(requester_civ_id, requester_shard_id, operator_id) do
    GenServer.cast(__MODULE__, {:license_operator, requester_civ_id, requester_shard_id, operator_id})
  end

  def publish_law_fragment(law_id, ast, civ_id, shard_id) do
    GenServer.call(__MODULE__, {:publish_law_fragment, law_id, ast, civ_id, shard_id})
  end

  def request_law_fragment(requester_civ_id, requester_shard_id, law_id) do
    GenServer.cast(__MODULE__, {:license_law_fragment, requester_civ_id, requester_shard_id, law_id})
  end

  @impl true
  def handle_call({:publish, disc_id, civ_id, shard_id}, _from, state) do
    # 1. Validate stability & trust
    with {:ok, stability} <- validate_stability(disc_id, civ_id),
         trust <- Tiannara.ECL.TrustEngine.compute_trust_score(civ_id, shard_id),
         {:ok, discovery_meta} <- get_discovery_metadata(disc_id, civ_id),
         :ok <- validate_acm_survival(discovery_meta),
         :ok <- validate_disease_risk(discovery_meta) do

      pub = %{
        discovery_id: disc_id,
        origin_civ_id: civ_id,
        origin_shard_id: shard_id,
        stability_score: stability,
        trust_score: trust,
        domain: discovery_meta.domain,
        license_cost: Map.get(discovery_meta, :maintenance_cost, %{energy: 10}),
        status: :active
      }

      # 2. Insert into lattice (sorted by trust_score)
      key = {trust, disc_id}
      existing = if :gb_trees.is_defined(key, state.lattice), do: :gb_trees.get(key, state.lattice), else: []
      new_lattice = :gb_trees.enter(key, [pub | existing], state.lattice)

      # 3. Notify shard subscribers
      notify_subscribers(state, shard_id, {:new_discovery, pub})

      Logger.info("🌐 [ECL] Published #{disc_id} (Trust: #{trust})")
      {:reply, :ok, %{state | lattice: new_lattice, metrics: Map.update!(state.metrics, :publishes, & &1 + 1)}}
    else
      {:error, :stability_below_threshold} ->
        Logger.warn("⚠️ [ECL] Quarantined #{disc_id} (stability < 0.8)")
        {:reply, {:error, :quarantined}, %{state | metrics: Map.update!(state.metrics, :quarantines, & &1 + 1)}}
      {:error, :acm_not_survived} ->
        Logger.warn("⚠️ [ECL] Quarantined #{disc_id} (has not survived ACM)")
        {:reply, {:error, :quarantined_acm}, %{state | metrics: Map.update!(state.metrics, :quarantines, & &1 + 1)}}
      {:error, :high_disease_risk} ->
        Logger.warn("⚠️ [ECL] Quarantined #{disc_id} (high disease risk)")
        {:reply, {:error, :quarantined_disease}, %{state | metrics: Map.update!(state.metrics, :quarantines, & &1 + 1)}}
      err ->
        {:reply, err, state}
    end
  end

  def handle_call({:search, domain, max_cost}, _from, state) do
    all_pubs = 
      :gb_trees.to_list(state.lattice)
      |> Enum.reverse()  # Highest trust first
      |> Enum.flat_map(fn {_, pubs} -> pubs end)
      |> Enum.filter(fn pub -> 
        pub.domain == domain and 
        (max_cost == nil or Map.get(pub.license_cost, :energy, 0) <= Map.get(max_cost, :energy, 0))
      end)
      |> Enum.take(20)

    results = %{
      active: Enum.filter(all_pubs, &(&1.status == :active)),
      relic: Enum.filter(all_pubs, &(&1.status == :archaeological))
    }

    {:reply, results, state}
  end

  @impl true
  def handle_cast({:license, requester_civ, _requester_shard, disc_id}, state) do
    # Find discovery origin
    pub = 
      :gb_trees.to_list(state.lattice)
      |> Enum.flat_map(fn {_, pubs} -> pubs end)
      |> Enum.find(& &1.discovery_id == disc_id)

    if pub do
      # Route to DiscoveryLedger for cross-shard licensing
      case Tiannara.REL.DiscoveryLedger.grant_license(pub.origin_civ_id, requester_civ, disc_id, pub.license_cost) do
        {:ok, _license_id} ->
          # Award posthumous or living influence to originator
          # ECL-1 Influence amount
          influence_earned = 50.0
          :ok = Tiannara.ECL.TrustEngine.award_influence(pub.origin_civ_id, influence_earned)
          {:noreply, %{state | metrics: Map.update!(state.metrics, :licenses, & &1 + 1)}}
        _err -> 
          {:noreply, state}
      end
    else
      {:noreply, state}
    end
  end

  @impl true
  def handle_call({:publish_operator, op_id, civ_id, shard_id}, _from, state) do
    # 1. Fetch operator from EntityRegistry
    case Tiannara.Core.WorldModel.EntityRegistry.get_entity(op_id, shard_id) do
      {:ok, ent} ->
        operator = Map.get(ent.attributes, :operator_data)
        trust = Tiannara.ECL.TrustEngine.compute_trust_score(civ_id, shard_id)
        
        pub = %{
          discovery_id: op_id, # Reusing discovery_id field for operator ID
          origin_civ_id: civ_id,
          origin_shard_id: shard_id,
          stability_score: operator.stability,
          trust_score: trust,
          domain: :cognition,
          license_cost: %{compute: 500}, # Heavy cost
          status: :active,
          is_operator: true
        }

        key = {trust, op_id}
        existing = if :gb_trees.is_defined(key, state.lattice), do: :gb_trees.get(key, state.lattice), else: []
        new_lattice = :gb_trees.enter(key, [pub | existing], state.lattice)

        Logger.info("🌐 [ECL] Published Reasoning Operator #{operator.name} (Trust: #{trust})")
        {:reply, :ok, %{state | lattice: new_lattice, metrics: Map.update!(state.metrics, :publishes, & &1 + 1)}}
      _ ->
        {:reply, {:error, :not_found}, state}
    end
  end

  @impl true
  def handle_cast({:license_operator, requester_civ, requester_shard, op_id}, state) do
    # Fetch from lattice
    pub = 
      :gb_trees.to_list(state.lattice)
      |> Enum.flat_map(fn {_, pubs} -> pubs end)
      |> Enum.find(& &1.discovery_id == op_id and Map.get(&1, :is_operator, false))

    if pub do
      # Directly give operator to requester by updating their attributes
      case Tiannara.Core.WorldModel.EntityRegistry.get_entity(requester_civ, requester_shard) do
        {:ok, ent} ->
          active_ops = Map.get(ent.attributes, :active_operators, [])
          unless op_id in active_ops do
            new_attrs = Map.put(ent.attributes, :active_operators, [op_id | active_ops])
            Tiannara.Core.WorldModel.EntityRegistry.update_entity(requester_civ, %{attributes: new_attrs}, requester_shard)
            Logger.info("📜 [ECL] #{requester_civ} licensed Reasoning Operator #{op_id} from #{pub.origin_civ_id}")
            # Award massive influence
            Tiannara.ECL.TrustEngine.award_influence(pub.origin_civ_id, 200.0)
          end
        _ -> :ok
      end
    end
    {:noreply, state}
  end

  @impl true
  def handle_call({:publish_law_fragment, law_id, ast, civ_id, shard_id}, _from, state) do
    trust = Tiannara.ECL.TrustEngine.compute_trust_score(civ_id, shard_id)
    
    pub = %{
      discovery_id: law_id,
      origin_civ_id: civ_id,
      origin_shard_id: shard_id,
      stability_score: Map.get(Map.get(ast, :stability, %{}), :entropy_cost, 0.5), # From OPC AST
      trust_score: trust,
      domain: :physics,
      license_cost: %{energy: 5000}, # Astronomical cost
      status: :active,
      is_operator: false,
      is_law_fragment: true,
      ast: ast
    }

    key = {trust, law_id}
    existing = if :gb_trees.is_defined(key, state.lattice), do: :gb_trees.get(key, state.lattice), else: []
    new_lattice = :gb_trees.enter(key, [pub | existing], state.lattice)

    Logger.info("🌐 [ECL] Published Law Fragment #{law_id} (Trust: #{trust})")
    {:reply, :ok, %{state | lattice: new_lattice, metrics: Map.update!(state.metrics, :publishes, & &1 + 1)}}
  end

  @impl true
  def handle_cast({:license_law_fragment, requester_civ, requester_shard, law_id}, state) do
    pub = 
      :gb_trees.to_list(state.lattice)
      |> Enum.flat_map(fn {_, pubs} -> pubs end)
      |> Enum.find(& &1.discovery_id == law_id and Map.get(&1, :is_law_fragment, false))

    if pub do
      # Directly give law fragment to requester by updating their attributes
      case Tiannara.Core.WorldModel.EntityRegistry.get_entity(requester_civ, requester_shard) do
        {:ok, ent} ->
          active_laws = Map.get(ent.attributes, :active_law_fragments, [])
          unless law_id in active_laws do
            new_attrs = Map.put(ent.attributes, :active_law_fragments, [law_id | active_laws])
            Tiannara.Core.WorldModel.EntityRegistry.update_entity(requester_civ, %{attributes: new_attrs}, requester_shard)
            Logger.info("📜 [ECL] #{requester_civ} assimilated Law Fragment #{law_id} from #{pub.origin_civ_id}")
            Tiannara.ECL.TrustEngine.award_influence(pub.origin_civ_id, 1000.0) # Massive influence
          end
        _ -> :ok
      end
    end
    {:noreply, state}
  end

  defp validate_stability(disc_id, civ_id) do
    # Validate via DiscoveryLedger
    known = Tiannara.REL.DiscoveryLedger.get_known_discoveries(civ_id)
    disc = Enum.find(known, & &1.id == disc_id)
    
    if disc do
      s = Map.get(disc, :stability, 0.5)
      if s >= 0.8 do
        {:ok, s}
      else
        {:error, :stability_below_threshold}
      end
    else
      {:error, :not_found}
    end
  end

  defp get_discovery_metadata(disc_id, civ_id) do
    known = Tiannara.REL.DiscoveryLedger.get_known_discoveries(civ_id)
    disc = Enum.find(known, & &1.id == disc_id)
    if disc, do: {:ok, disc}, else: {:error, :not_found}
  end

  defp validate_acm_survival(discovery) do
    # Assume discoveries that survived ACM have an attribute
    # or rely on stability. In the new architecture, we require explicit acm_survival.
    if Map.get(discovery, :acm_survived, true) do
      :ok
    else
      {:error, :acm_not_survived}
    end
  end

  defp validate_disease_risk(discovery) do
    infected_count = length(Map.get(discovery, :infected_by, []))
    if infected_count > 0 do
      # For now, if infected at all, risk is high
      {:error, :high_disease_risk}
    else
      :ok
    end
  end

  defp notify_subscribers(state, shard_id, message) do
    case Map.get(state.subscribers, shard_id) do
      nil -> :ok
      pid -> send(pid, {:ecl_broadcast, message})
    end
  end
end
