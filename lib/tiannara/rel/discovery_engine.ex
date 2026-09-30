defmodule Tiannara.REL.DiscoveryEngine do
  @moduledoc """
  Drives the discovery mechanics, incorporating Epistemic Genomes, Quantum Leaps,
  and Cross-domain Recombinations.
  """

  require Logger

  alias Tiannara.Core.WorldModel.Discovery
  alias Tiannara.REL.EconomyEngine
  alias Tiannara.REL.DiscoveryLedger

  @domains Tiannara.DomainCortex.l1_discovery_domains()

  @doc "Attempt to make a discovery. Returns {:ok, %Discovery{}} or {:error, reason}."
  def attempt_discovery(civ_id, shard_id) do
    # Fetch EpistemicGenome
    entity = Tiannara.Core.WorldModel.EntityRegistry.get_entity(civ_id, shard_id)
    case entity do
      {:ok, civ_entity} ->
        genome = Map.get(civ_entity.attributes, :epistemic_genome)
        if genome do
          process_discovery_attempt(civ_id, shard_id, genome)
        else
          {:error, :no_genome}
        end
      _ ->
        {:error, :civ_not_found}
    end
  end

  defp process_discovery_attempt(civ_id, shard_id, genome) do
    # High abstraction + novelty seeking = quantum leap probability
    quantum_leap_chance = (genome.abstraction_bias * genome.novelty_seeking) * 0.10
    is_quantum_leap = :rand.uniform() < quantum_leap_chance

    if is_quantum_leap do
      attempt_quantum_leap(civ_id, shard_id, genome)
    else
      # 10% chance for recombination if they have multiple discoveries
      known = DiscoveryLedger.get_known_discoveries(civ_id)
      if length(known) >= 2 and :rand.uniform() < 0.10 do
        attempt_recombination(civ_id, shard_id, known, genome)
      else
        attempt_normal_discovery(civ_id, shard_id, genome)
      end
    end
  end

  defp attempt_quantum_leap(civ_id, shard_id, _genome) do
    Logger.info("🌌 [DiscoveryEngine] #{civ_id} is attempting a Quantum Leap!")
    cost = %{compute: 2000, attention: 1000}
    
    case EconomyEngine.consume(civ_id, cost) do
      :ok ->
        domain = Enum.random(@domains)
        disc = Discovery.new(%{
          id: "disc_ql_#{:crypto.strong_rand_bytes(4) |> Base.encode16()}",
          name: "Quantum Leap candidate in #{String.capitalize(to_string(domain))}",
          domain: domain,
          originator_civ_id: civ_id,
          complexity_cost: 50,
          prerequisites: []
        })
        validate_and_register(civ_id, shard_id, disc)
      err ->
        Logger.debug("❌ [DiscoveryEngine] #{civ_id} failed Quantum Leap due to costs.")
        err
    end
  end

  defp attempt_recombination(civ_id, shard_id, known, _genome) do
    parent_a = Enum.random(known)
    parent_b = Enum.random(known)
    
    if parent_a.id == parent_b.id do
      {:error, :same_parents}
    else
      Logger.info("🧬 [DiscoveryEngine] #{civ_id} recombining #{parent_a.name} and #{parent_b.name}")
      cost = %{compute: 200, attention: 100}
      
      case EconomyEngine.consume(civ_id, cost) do
        :ok ->
          domain = parent_a.domain # Inherits domain of A
          disc = Discovery.new(%{
            id: "disc_rec_#{:crypto.strong_rand_bytes(4) |> Base.encode16()}",
            name: "Recombination candidate: #{parent_a.name} x #{parent_b.name}",
            domain: domain,
            originator_civ_id: civ_id,
            complexity_cost: 20,
            parents: [parent_a.id, parent_b.id],
            evidence: []
          })
          validate_and_register(civ_id, shard_id, disc)
        err -> err
      end
    end
  end

  defp attempt_normal_discovery(civ_id, shard_id, _genome) do
    cost = %{compute: 100, attention: 50}
    case EconomyEngine.consume(civ_id, cost) do
      :ok ->
        domain = Enum.random(@domains)
        disc = Discovery.new(%{
          id: "disc_norm_#{:crypto.strong_rand_bytes(4) |> Base.encode16()}",
          name: "Advance candidate in #{String.capitalize(to_string(domain))}",
          domain: domain,
          originator_civ_id: civ_id,
          complexity_cost: 10,
          evidence: []
        })
        validate_and_register(civ_id, shard_id, disc)
      err -> err
    end
  end

  defp validate_and_register(civ_id, shard_id, discovery) do
    case Tiannara.OAVL.DiscoveryVerifier.evaluate(discovery) do
      {:ok, validated} ->
        case Tiannara.OED.AdoptionEvaluator.evaluate(civ_id, shard_id, validated) do
          {:safe, _} ->
            DiscoveryLedger.register_discovery(civ_id, validated)
            {:ok, validated}
          {:quarantine, id} -> {:error, {:quarantined, id}}
        end
      {:error, reason} ->
        {:error, {:discovery_unvalidated, reason}}
    end
  end
end
