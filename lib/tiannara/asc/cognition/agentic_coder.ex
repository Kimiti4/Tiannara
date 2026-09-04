defmodule Tiannara.ASC.Cognition.AgenticCoder do
  @moduledoc """
  Phase 14: Generates real code patches using LLM inference, constrained by 
  the Institutional Memory (ADRs) and the Constitution.
  """
  alias Tiannara.ASC.Cognition.LLMGateway
  alias Tiannara.ASC.Memory.InstitutionalMemory
  require Logger

  def generate_real_patch(task, design_doc, budget) do
    Logger.info("💻 [AgenticCoder] Generating real unified diff via LLM...")
    
    # 1. Fetch Context (Institutional Memory)
    # Mocking InstitutionalMemory if it's not defined for this exact call yet
    adrs = 
      if Code.ensure_loaded?(InstitutionalMemory) and function_exported?(InstitutionalMemory, :get_relevant_adrs, 1) do
        InstitutionalMemory.get_relevant_adrs(task.goal)
      else
        [%{id: "adr_01", decision: "Use functional core, imperative shell"}]
      end
    
    system_prompt = """
    You are an elite Elixir/Python software engineer. 
    You must generate a valid unified diff patch to satisfy the design document.
    You MUST respect the following Architectural Decision Records (ADRs):
    #{Jason.encode!(adrs)}
    """

    user_prompt = """
    DESIGN DOCUMENT: #{Jason.encode!(design_doc)}
    TARGET FILE: #{Map.get(task, :target_file, "unknown")}
    
    Output strictly in JSON: {"diff": "...", "explanation": "..."}
    """

    schema = %{
      "type" => "object",
      "properties" => %{
        "diff" => %{"type" => "string"},
        "explanation" => %{"type" => "string"}
      }
    }

    case LLMGateway.reason(system_prompt, user_prompt, schema, budget) do
      {:ok, %{"diff" => diff, "explanation" => explanation}} ->
        Logger.info("✅ [AgenticCoder] Generated patch. Explanation: #{explanation}")
        {:ok, diff}
      {:error, _, _} ->
        {:error, :generation_failed}
    end
  end
end
