defmodule Tiannara.UniverseServer do
  @moduledoc """
  Global Orchestrator for the Cognitive Ecology.
  Aggregates civilization telemetry and emits the global field state to Python.
  """
  use GenServer
  use TiannaraRuntime.Layer, authority: :ecology, can_call: [:execution], can_receive: [:execution, :constraint]
  require Logger

  @tick_interval 100
  @telemetry_interval 1000

  defstruct [
    :id,
    :worlds,
    :global_entropy,
    :constraint_field,
    :tick,
    :event_bus,
    :civ_states,
    :pending_bursts,
    :olef_field
  ]

  # API
  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: via(opts[:id]))
  end

  def tick(universe_id) do
    GenServer.cast(via(universe_id), :tick)
  end

  def add_world(universe_id, world_id) do
    GenServer.call(via(universe_id), {:add_world, world_id})
  end

  def snapshot(universe_id \\ :alpha_universe) do
    GenServer.call(via(universe_id), :snapshot)
  end

  def get_metrics(universe_id \\ :alpha_universe) do
    GenServer.call(via(universe_id), :get_metrics)
  end

  def inject_perturbation(params, universe_id \\ :alpha_universe) do
    GenServer.cast(via(universe_id), {:inject_perturbation, params})
  end

  def init(opts) do
    :inets.start()
    
    # 🌌 SEED CIVILIZATIONS FOR SOPL DASHBOARD AFTER BOOT
    Process.send_after(self(), :seed_universes, 2000)

    # Initialize the Rust SIMD OLEF Field
    olef_field = Tiannara.OlefNif.initialize(64, 64)

    state = %__MODULE__{
      id: opts[:id],
      worlds: %{},
      global_entropy: 0.5,
      constraint_field: %{},
      tick: 0,
      event_bus: opts[:event_bus],
      civ_states: %{},
      pending_bursts: [],
      olef_field: olef_field
    }

    schedule_tick()
    schedule_telemetry()
    {:ok, state}
  end

  # MESSAGES
  def handle_cast({:civilization_telemetry, civ_state}, state) do
    # Aggregate civilization state delta
    compressed_civ = %{
      "id" => civ_state.id,
      "status" => to_string(civ_state.status),
      "energy" => civ_state.epistemic_energy,
      "coherence" => civ_state.cognitive_coherence,
      "collapse_risk" => civ_state.collapse_risk,
      "policy" => to_string(civ_state.policy_state),
      "agent_count" => length(civ_state.agents),
      "memory_size" => map_size(civ_state.memory_graph.lemmas),
      "factions" => civ_state.factions,
      "mutation_rate" => Map.get(civ_state.cultural_identity, :exploration_bias, 0.0),
      "reproduction_rate" => Map.get(civ_state.cultural_identity, :theorem_sharing, 0.0),
      "niche_affinity" => Map.get(civ_state.cultural_identity, :synthesis_preference, 0.0)
    }
    new_civs = Map.put(state.civ_states, civ_state.id, compressed_civ)
    {:noreply, %{state | civ_states: new_civs}}
  end

  def handle_cast({:burst_event, event}, state) do
    new_bursts = [event | state.pending_bursts]
    # Trigger immediate burst telemetry
    emit_telemetry_payload(state.civ_states, new_bursts, state)
    {:noreply, %{state | pending_bursts: []}}
  end

  def handle_info(:emit_telemetry, state) do
    emit_telemetry_payload(state.civ_states, state.pending_bursts, state)
    schedule_telemetry()
    {:noreply, %{state | pending_bursts: []}}
  end

  def handle_info(:seed_universes, state) do
    # Spawn World 1
    {:ok, pid1} = Tiannara.WorldServer.start_link(%{id: "hyperbolic_space", universe: state.id})
    Tiannara.WorldServer.spawn_civilization(pid1, "riemann_seekers")
    Tiannara.WorldServer.spawn_civilization(pid1, "poincare_purists")
    
    # Spawn World 2
    {:ok, pid2} = Tiannara.WorldServer.start_link(%{id: "discrete_manifold", universe: state.id})
    Tiannara.WorldServer.spawn_civilization(pid2, "np_hard_factions")
    Tiannara.WorldServer.spawn_civilization(pid2, "navier_stokes_cult")
    
    new_worlds = state.worlds
      |> Map.put("hyperbolic_space", pid1)
      |> Map.put("discrete_manifold", pid2)
      
    IO.puts("🌌 Booted seed civilizations for observation.")
    {:noreply, %{state | worlds: new_worlds}}
  end

  def handle_info(:tick, state) do
    # 1. MSCL: Clamp bounds (conceptualized as part of NIF for speed or done locally)
    field = Tiannara.OlefNif.clamp_pressure(state.olef_field)
    
    # 2. GRCC: Inject Novelty
    field = Tiannara.OlefNif.inject_novelty(field, state.tick)
    
    # 3. Rust SIMD Core: Diffusion Truth
    field = Tiannara.OlefNif.step(field)

    decayed_bursts =
      Enum.map(state.pending_bursts, fn burst ->
        updated_amount = max(0.0, Map.get(burst, :amount, 0.0) - 0.5)
        Map.put(burst, :amount, updated_amount)
      end)

    filtered_bursts = Enum.filter(decayed_bursts, fn burst -> Map.get(burst, :amount, 0.0) > 0.01 end)

    new_state =
      state
      |> increment_tick()
      |> propagate_world_ticks()
      |> compute_global_entropy()
      |> Map.put(:pending_bursts, filtered_bursts)
      |> Map.put(:global_entropy, max(0.1, state.global_entropy * 0.98))
      
    new_state = %{new_state | olef_field: field}

    schedule_tick()
    {:noreply, new_state}
  end

  def handle_cast(:tick, state) do
    {:noreply, handle_info(:tick, state) |> elem(1)}
  end

  def handle_call({:add_world, world_id}, _from, state) do
    {:ok, pid} = Tiannara.WorldServer.start_link(%{
      id: world_id,
      universe: state.id
    })
    new_worlds = Map.put(state.worlds, world_id, pid)
    {:reply, :ok, %{state | worlds: new_worlds}}
  end

  def handle_call(:snapshot, _from, state) do
    {:reply, state, state}
  end

  def handle_call(:get_metrics, _from, state) do
    metrics = %{
      tick: state.tick,
      global_entropy: state.global_entropy,
      population: map_size(state.civ_states),
      constraint_load: compute_constraint_load(state),
      pressure_gradient: compute_pressure_gradient(state),
      anomaly_count: length(state.pending_bursts)
    }

    {:reply, metrics, state}
  end

  def handle_cast({:inject_perturbation, params}, state) do
    niche_id = Map.get(params, :niche_id, "niche_1")
    amount = Map.get(params, :amount, Map.get(params, :resource_amount, 10))

    burst = %{
      type: Map.get(params, :type, :resource_depletion),
      niche_id: niche_id,
      amount: amount,
      timestamp: System.monotonic_time(:millisecond)
    }

    updated_constraint_field = Map.put(state.constraint_field, niche_id, amount)
    updated_entropy = min(1.0, state.global_entropy + amount * 0.01)

    updated_state = %{
      state |
      constraint_field: updated_constraint_field,
      global_entropy: updated_entropy,
      pending_bursts: [burst | state.pending_bursts]
    }

    {:noreply, updated_state}
  end

  # INTERNALS
  defp schedule_tick do
    Process.send_after(self(), :tick, @tick_interval)
  end

  defp schedule_telemetry do
    Process.send_after(self(), :emit_telemetry, @telemetry_interval)
  end

  defp increment_tick(state), do: %{state | tick: state.tick + 1}

  defp propagate_world_ticks(state) do
    Enum.each(state.worlds, fn {_id, pid} ->
      GenServer.cast(pid, :world_tick)
    end)
    state
  end

  defp compute_global_entropy(state) do
    civs = Map.values(state.civ_states)
    entropy =
      if civs == [] do
        0.0
      else
        energy_total = Enum.reduce(civs, 0.0, fn c, acc -> acc + Map.get(c, "energy", 0.0) end)
        coherence_total = Enum.reduce(civs, 0.0, fn c, acc -> acc + Map.get(c, "coherence", 0.0) end)
        count = length(civs)
        normalized_energy = min(1.0, energy_total / max(1.0, count * 100.0))
        normalized_coherence = min(1.0, coherence_total / max(1.0, count))
        max(0.0, 1.0 - ((normalized_energy + normalized_coherence) / 2.0))
      end

    %{state | global_entropy: entropy}
  end

  defp emit_telemetry_payload(civ_states, bursts, state) do
    grcc = build_grcc_channel(civ_states)
    mscl = build_mscl_channel(civ_states, state)
    olef = build_olef_channel(state)
    cis = build_cis_channel(civ_states, bursts)
    ctl = build_ctl_channel(civ_states)

    payload = %{
      "t" => System.os_time(:millisecond),
      "channels" => %{
        "l1_grcc" => grcc,
        "l2_mscl" => mscl,
        "l3_olef" => olef,
        "l4_cis" => cis,
        "l5_ctl" => ctl
      },
      "world_state" => %{
        "civilization_count" => map_size(civ_states),
        "entropy_field" => state.global_entropy,
        "olef_field_pressure" => state.olef_field.pressure,
        "olef_field_entropy" => state.olef_field.entropy,
        "olef_field_curvature" => state.olef_field.curvature,
        "olef_law_diffusion" => Enum.map(state.olef_field.population, fn law -> law.diffusion end),
        "olef_law_decay" => Enum.map(state.olef_field.population, fn law -> law.decay end)
      },
      "burst_events" => Enum.map(bursts, fn e -> 
        # Safely convert atom keys to string
        Map.new(e, fn {k, v} -> {to_string(k), if(is_atom(v), do: to_string(v), else: v)} end)
      end)
    }

    try do
      json_body = Jason.encode!(payload)
      url = 'http://localhost:8004/api/v1/meta-ecology/ingest'
      headers = [{'content-type', 'application/json'}]
      
      # Fire and forget async request
      :httpc.request(:post, {url, headers, 'application/json', json_body}, [], [])
    rescue
      e -> Logger.error("Failed to encode/emit telemetry: #{inspect(e)}")
    end
  end

  defp compute_global_collapse_vector(civ_states) do
    total_risk = Enum.reduce(Map.values(civ_states), 0.0, fn c, acc -> acc + Map.get(c, "collapse_risk", 0.0) end)
    avg_risk = if map_size(civ_states) > 0, do: total_risk / map_size(civ_states), else: 0.0
    avg_risk
  end

  defp compute_global_drift_velocity(civ_states) do
    values = Map.values(civ_states)
    count = length(values)

    if count > 1 do
      avg_coherence = compute_global_coherence(civ_states)
      coherence_deviation =
        Enum.reduce(values, 0.0, fn c, acc ->
          acc + abs(Map.get(c, "coherence", 0.0) - avg_coherence)
        end) / count

      min(1.0, coherence_deviation)
    else
      0.0
    end
  end

  defp compute_global_coherence(civ_states) do
    total_coherence = Enum.reduce(Map.values(civ_states), 0.0, fn c, acc -> acc + Map.get(c, "coherence", 0.0) end)
    if map_size(civ_states) > 0, do: total_coherence / map_size(civ_states), else: 1.0
  end

  defp compute_constraint_load(state) do
    risks =
      Enum.map(Map.values(state.civ_states), fn civ ->
        Map.get(civ, "collapse_risk", 0.0)
      end)

    average(risks)
  end

  defp compute_pressure_gradient(state) do
    pressure = Map.get(state.olef_field, :pressure, [])

    if is_list(pressure) and length(pressure) > 1 do
      pressure
      |> Enum.chunk_every(2, 1, :discard)
      |> Enum.map(fn [a, b] -> abs(b - a) end)
      |> average()
    else
      0.0
    end
  end

  defp build_grcc_channel(civ_states) do
    civs = Map.values(civ_states)

    lineage_population_vectors =
      Enum.map(civs, fn civ ->
        %{
          "id" => Map.get(civ, "id"),
          "agent_count" => Map.get(civ, "agent_count", 0),
          "coherence" => Map.get(civ, "coherence", 0.0),
          "energy" => Map.get(civ, "energy", 0.0)
        }
      end)

    niche_occupancy_map =
      Enum.map(civs, fn civ ->
        %{
          "id" => Map.get(civ, "id"),
          "policy" => Map.get(civ, "policy", "unknown"),
          "factions" => Map.get(civ, "factions", %{})
        }
      end)

    mutation_rates = Enum.map(civs, &Map.get(&1, "mutation_rate", 0.0))
    reproduction_rates = Enum.map(civs, &Map.get(&1, "reproduction_rate", 0.0))

    %{
      "lineage_population_vectors" => lineage_population_vectors,
      "niche_occupancy_map" => niche_occupancy_map,
      "mutation_reproduction_variance" => %{
        "mutation_rate_variance" => variance(mutation_rates),
        "reproduction_rate_variance" => variance(reproduction_rates)
      }
    }
  end

  defp build_mscl_channel(civ_states, state) do
    civs = Map.values(civ_states)
    loads = Enum.map(civs, fn civ -> max(0.0, 1.0 - Map.get(civ, "coherence", 0.0)) end)
    pressures = Enum.map(civs, fn civ -> Map.get(civ, "collapse_risk", 0.0) end)

    %{
      "global_constraint_load" => loads,
      "divergence_pressure" => pressures,
      "entropy_field" => state.global_entropy
    }
  end

  defp build_olef_channel(state) do
    pressure = state.olef_field.pressure
    curvature = state.olef_field.curvature

    %{
      "node_imbalance" => Enum.zip(pressure, curvature) |> Enum.map(fn {p, c} -> p - c end),
      "pressure_gradients" => gradients(pressure),
      "fields" => %{
        "pressure" => pressure,
        "entropy" => state.olef_field.entropy,
        "curvature" => curvature
      },
      "law_diffusion" => Enum.map(state.olef_field.population, fn law -> law.diffusion end),
      "law_decay" => Enum.map(state.olef_field.population, fn law -> law.decay end)
    }
  end

  defp build_cis_channel(civ_states, bursts) do
    civs = Map.values(civ_states)

    anomaly_stream =
      Enum.map(civs, fn civ ->
        %{
          "id" => Map.get(civ, "id"),
          "collapse_risk" => Map.get(civ, "collapse_risk", 0.0),
          "coherence" => Map.get(civ, "coherence", 0.0)
        }
      end)

    intervention_triggers =
      Enum.map(bursts, fn e ->
        Map.new(e, fn {k, v} -> {to_string(k), if(is_atom(v), do: to_string(v), else: v)} end)
      end)

    %{
      "anomaly_stream" => anomaly_stream,
      "intervention_triggers" => intervention_triggers
    }
  end

  defp build_ctl_channel(civ_states) do
    %{
      "semantic_drift_velocity" => compute_global_drift_velocity(civ_states),
      "branch_divergence_index" => compute_global_collapse_vector(civ_states)
    }
  end

  defp average([]), do: 0.0

  defp average(values) when is_list(values) do
    Enum.sum(values) / max(length(values), 1)
  end

  defp variance([]), do: 0.0
  defp variance(values) do
    count = length(values)
    mean = Enum.sum(values) / count
    Enum.reduce(values, 0.0, fn x, acc -> acc + :math.pow(x - mean, 2) end) / count
  end

  defp gradients([]), do: []
  defp gradients([_single]), do: [0.0]
  defp gradients(values) do
    [0.0 | gradients(values, nil)]
  end

  defp gradients([], _prev), do: []
  defp gradients([h | t], nil), do: gradients(t, h)
  defp gradients([h | t], prev), do: [h - prev | gradients(t, h)]

  defp via(id), do: {:via, Registry, {Tiannara.Registry, {:universe, id}}}
end
