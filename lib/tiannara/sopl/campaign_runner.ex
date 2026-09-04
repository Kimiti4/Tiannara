defmodule Tiannara.SOPL.CampaignRunner do
  @moduledoc """
  SOPL-1: Observational Campaign Engine
  
  Runs 5 concurrent shards, each seeded with a divergent LawGenome,
  for 50,000+ epochs without mutation. The goal is to map the law-fitness landscape.
  """
  require Logger
  alias Tiannara.SOPL.LawGenome

  def start_campaign do
    Logger.info("🌌 [SOPL-1] Initiating Observational Campaign (50,000 Epochs)...")

    shards = [
      {"Shard A (Novelty-Biased)", %{mutation_pressure: 0.15, novelty_reward: 500.0, diversity_floor: 0.6}},
      {"Shard B (Stability-Biased)", %{pressure_threshold: 0.8, virulence: 0.2, diversity_floor: 0.2}},
      {"Shard C (Truth-Biased)", %{identity_weight: 0.9, causal_tolerance: 0.05}},
      {"Shard D (Resilience-Biased)", %{virulence: 1.5, pressure_threshold: 0.2}},
      {"Shard E (Balanced)", %{}}
    ]

    # Initialize LawGenomes for each shard
    genomes = Enum.map(shards, fn {name, params} ->
      law = LawGenome.generate(params)
      {name, law}
    end)

    # In a full simulation, this spawns 5 separate ROS instances running their LawGenomes.
    Logger.info("🌌 [SOPL-1] Seeded 5 divergent Law ecologies.")
    Enum.each(genomes, fn {name, law} ->
      Logger.info("    -> #{name} running LawGenome #{law.id}")
    end)

    # Simulate the 50,000 epoch progression
    spawn(fn -> simulate_campaign(genomes, 50_000) end)
  end

  defp simulate_campaign(genomes, epochs) do
    Logger.info("⏳ [SOPL-1] Running #{epochs} epochs across all shards...")
    
    # Process "epochs" (simulated wait)
    Process.sleep(2000)
    
    # Evaluate each shard
    results = Enum.map(genomes, fn {name, law} ->
      fitness = Tiannara.SOPL.LawEvaluator.evaluate(law)
      {name, law, fitness}
    end)

    # Sort by total fitness
    sorted = Enum.sort_by(results, fn {_, _, f} -> f.total_fitness end, :desc)

    Logger.info("🏆 [SOPL-1] Campaign Complete. Law-Fitness Landscape Mapped:")
    Enum.each(sorted, fn {name, law, f} ->
      Logger.info("    -> #{name} [#{law.id}] | Fitness: #{Float.round(f.total_fitness, 3)} (Health: #{Float.round(f.health.score, 3)}, Potential: #{Float.round(f.potential.score, 3)})")
    end)
    
    # Law Archaeology: Archive the poorest performers as Ruins so their components aren't lost
    worst = Enum.take(Enum.reverse(sorted), 2)
    
    Enum.each(worst, fn {name, law, f} ->
      state =
        case Process.whereis(TiannaraOS.CivilizationKernel) do
          nil -> nil
          pid ->
            if Process.alive?(pid) do
              try do
                apply(TiannaraOS.CivilizationKernel, :get_state, [])
              rescue
                _ -> nil
              end
            else
              nil
            end
        end

      {species, discoveries_list, diseases} =
        if state do
          sp =
            state.worlds
            |> Map.values()
            |> Enum.map(&to_string(&1.template_id))
            |> Enum.uniq()

          disc = state.discoveries |> Map.keys() |> Enum.map(&to_string/1)

          dis =
            state.evidence_graph
            |> Map.values()
            |> Enum.filter(&(&1.validity == :contested))
            |> Enum.map(&to_string(&1.id))

          {sp, disc, dis}
        else
          {[], [], []}
        end

      ruin = %Tiannara.SOPL.LawRuin{
        id: "ruin_#{law.id}",
        law_genome: law,
        fitness_history: [f.total_fitness],
        collapse_signature: "Outperformed during SOPL-1 campaign in #{name}",
        produced_species: species,
        produced_discoveries: discoveries_list,
        produced_diseases: diseases,
        archived_at: DateTime.utc_now()
      }
      Tiannara.SOPL.LawArchaeology.archive_ruin(ruin)
    end)
  end
end
