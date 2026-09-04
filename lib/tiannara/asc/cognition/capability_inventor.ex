defmodule Tiannara.ASC.Cognition.CapabilityInventor do
  @moduledoc """
  Phase 14: Replaces heuristic mocking with genuine LLM-driven invention.
  Asks the reasoning engine to analyze deep friction and invent a novel capability.
  """
  alias Tiannara.ASC.Cognition.LLMGateway
  alias Tiannara.ASC.Ecology.{Capability, CapabilityRegistry}
  require Logger

  @system_prompt """
  You are the Chief Organizational Architect of an Autonomous Software Civilization.
  Your goal is to analyze engineering friction and invent NEW cognitive tools or agent roles 
  to solve systemic bottlenecks. Do not suggest existing roles (Architect, Coder, Auditor).
  You must output strict JSON.
  """

  @json_schema %{
    "type" => "object",
    "properties" => %{
      "capability_name" => %{"type" => "string"},
      "capability_type" => %{"type" => "string", "enum" => ["agent_role", "cognitive_tool", "research_instrument"]},
      "rationale" => %{"type" => "string"},
      "trigger_condition" => %{"type" => "object"},
      "implementation_strategy" => %{"type" => "string"}
    },
    "required" => ["capability_name", "capability_type", "rationale"]
  }

  def invent_from_friction(friction_telemetry, mission_budget) do
    Logger.info("🧠 [CognitiveInventor] Analyzing friction telemetry via LLM...")
    
    user_prompt = """
    CURRENT MISSION FRICTION REPORT:
    - Legacy Codebase Failures: #{friction_telemetry[:legacy_codebase_failures] || 0}
    - Cross-Domain Regressions: #{friction_telemetry[:cross_domain_regressions] || 0}
    - External API Contract Failures: #{friction_telemetry[:external_api_failures] || 0}
    - Loopback Rate: #{friction_telemetry[:loopback_rate] || 0}
    
    EXISTING ECOLOGY ROLES:
    Architect, Coder, Auditor, Tester, Context Injector, Technical Debt Archaeologist.
    
    INVENT a novel capability to solve the primary source of friction.
    """

    case LLMGateway.reason(@system_prompt, user_prompt, @json_schema, mission_budget) do
      {:ok, invention} ->
        Logger.info("💡 [CognitiveInventor] LLM Invented: #{invention["capability_name"]}")
        Logger.info("   Rationale: #{invention["rationale"]}")
        
        # Register the genuinely invented capability into the Ecology
        cap = %Capability{
          id: "llm_#{:erlang.unique_integer([:positive])}",
          name: invention["capability_name"],
          type: String.to_atom(invention["capability_type"]),
          trigger_condition: invention["trigger_condition"],
          implementation: fn task -> execute_invented_strategy(task, invention["implementation_strategy"]) end,
          lineage: :llm_synthesis
        }
        
        CapabilityRegistry.register(cap)
        {:ok, cap}
        
      {:error, reason, details} ->
        Logger.error("❌ [CognitiveInventor] Invention failed: #{reason} - #{details}")
        {:error, reason}
    end
  end

  defp execute_invented_strategy(task, strategy) do
    # In Phase 15, this strategy string is passed to an Agentic Executor 
    # which uses the RealityBridge to actually perform the described action.
    Logger.info("      🧩 [#{task.id}] Executing LLM Strategy: #{strategy}")
    Map.put(task, :llm_enriched, true)
  end
end
