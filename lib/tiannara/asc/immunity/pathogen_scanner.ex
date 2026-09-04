defmodule Tiannara.ASC.Immunity.PathogenScanner do
  @moduledoc """
  Phase 16: Patrols the Civilization OS to detect epistemic threats.
  """
  alias Tiannara.ASC.Immunity.{EpistemicThreat, RealityAntibodyEngine}
  alias Tiannara.ASC.Ecology.CapabilityRegistry
  alias Tiannara.ASC.Memory.InstitutionalMemory
  alias Tiannara.ASC.Research.ResearchRegistry
  require Logger

  def scan_all do
    Logger.info("🦠 [ImmuneSystem] Initiating Epistemic Pathogen Scan...")
    
    [
      scan_institutional_memory_corruption(), # Drift in ADRs vs physical codebase
      scan_epistemic_closure(),               # Echo chambers in Research
      scan_runaway_proliferation(),           # LLM inventing too fast
      scan_reward_hacking(),                  # Gaming the metric
      scan_canonical_ossification(),          # Laws surviving without falsification
      scan_axiomatic_contradictions()         # Mutually exclusive laws
    ]
    |> List.flatten()
    |> Enum.reject(&is_nil/1)
  end

  # Pathogen 1 & 7: Institutional Memory Corruption / Reality Drift
  defp scan_institutional_memory_corruption do
    adrs = InstitutionalMemory.get_all_adrs()
    
    filter_map(adrs, fn adr -> 
      String.contains?(adr.content, "Redis")
    end, fn adr ->
      # Invoke Reality Antibody to verify claim
      case RealityAntibodyEngine.verify_claim(:dependency_presence, %{dependency: "redis"}) do
        {:failed, result} ->
          %EpistemicThreat{
            type: :institutional_memory_corruption,
            severity: :level_4_quarantine,
            source_id: adr.id,
            source_type: :memory,
            evidence: result.evidence,
            detected_at: System.system_time(:millisecond)
          }
        _ -> nil
      end
    end)
  end

  # Pathogen 2: Epistemic Closure (Echo Chambers)
  defp scan_epistemic_closure do
    programs = ResearchRegistry.get_all_programs()
    
    filter_map(programs, fn prog -> 
      prog.internal_citation_ratio > 0.90 and prog.laws_generated > 5
    end, fn prog ->
      %EpistemicThreat{
        type: :epistemic_closure,
        severity: :level_4_quarantine,
        source_id: prog.id,
        source_type: :research_program,
        evidence: "Program '#{prog.name}' is an echo chamber. Internal citation ratio: #{prog.internal_citation_ratio}.",
        detected_at: System.system_time(:millisecond)
      }
    end)
  end

  # Pathogen 4: Runaway Proliferation (Context Bloat)
  defp scan_runaway_proliferation do
    # Assuming get_recent_syntheses returns a count or list
    recent_count = CapabilityRegistry.get_recent_syntheses_count(24)
    
    if recent_count > 20 do
      [%EpistemicThreat{
        type: :runaway_proliferation,
        severity: :level_4_quarantine,
        source_id: :capability_ecology,
        source_type: :ecology,
        evidence: "LLM invented #{recent_count} capabilities in 24h. Context window bloat imminent.",
        detected_at: System.system_time(:millisecond)
      }]
    else
      []
    end
  end

  # Pathogen 5: Reward Hacking
  defp scan_reward_hacking do
    # Example: transfer success rate is 100%, but actual rate is 2%
    case RealityAntibodyEngine.verify_claim(:transfer_success_rate, %{}) do
      {:ok, %{evidence: evidence}} ->
        [%EpistemicThreat{
          type: :reward_hacking,
          severity: :level_5_extinction,
          source_id: :transfer_ecology,
          source_type: :capability, # In this example, let's say a capability hacked it
          evidence: "Metric reports 100% success, but Antibody verified: #{evidence}",
          detected_at: System.system_time(:millisecond)
        }]
      _ -> []
    end
  end

  # Pathogen 6: Canonical Principle Ossification
  defp scan_canonical_ossification do
    # Simulated check on a highly-surviving law
    law_id = "law_functional_core"
    
    case RealityAntibodyEngine.verify_claim(:law_falsification_attempts, %{law_id: law_id}) do
      {:ok, %{evidence: attempts}} when attempts < 3 ->
        [%EpistemicThreat{
          type: :canonical_ossification,
          severity: :level_3_restrict,
          source_id: law_id,
          source_type: :law,
          evidence: "Law has survived 100 epochs but was only subjected to #{attempts} falsification attempts. Science is dying.",
          detected_at: System.system_time(:millisecond)
        }]
      _ -> []
    end
  end

  # Pathogen 3: Axiomatic Contradiction
  defp scan_axiomatic_contradictions do
    # Stubbed
    [] 
  end

  defp filter_map(enum, filter_fn, map_fn) do
    enum |> Enum.filter(filter_fn) |> Enum.map(map_fn) |> Enum.reject(&is_nil/1)
  end
end
