defmodule Tiannara.ASC.Cognition.LLMGateway do
  @moduledoc """
  Phase 14: The bridge between the Civilization OS and external Reasoning Engines.
  Handles API calls, token tracking, and strict JSON enforcement.
  """
  require Logger

  @provider System.get_env("LLM_PROVIDER", "anthropic") # or "gemini", "openai"

  @doc """
  Sends a structured prompt to the reasoning engine and demands a strict JSON response.
  Enforces the Constitution's compute budget via token tracking.
  """
  def reason(system_prompt, user_prompt, json_schema, budget_remaining) do
    Logger.info("🧠 [LLMGateway] Invoking #{@provider} (Budget Remaining: #{budget_remaining} tokens)")
    
    # In production, this uses Req or Finch to call the actual API
    # Here we define the contract for the structured output
    payload = build_payload(system_prompt, user_prompt, json_schema)
    
    case execute_api_call(payload) do
      {:ok, raw_json, tokens_used} ->
        if tokens_used > budget_remaining do
          {:error, :budget_exhausted, "LLM exceeded mission compute budget."}
        else
          parse_and_validate(raw_json, json_schema)
        end
    end
  end

  defp build_payload(sys, user, schema) do
    # Constructs the provider-specific payload (e.g., Anthropic's tool_use or Gemini's response_schema)
    %{
      system: sys,
      messages: [%{role: "user", content: user}],
      response_format: %{type: "json_object", schema: schema}
    }
  end

  defp execute_api_call(payload) do
    # MOCKED FOR WALKTHROUGH: In reality, this is `Req.post(url, json: payload, headers: headers)`
    system_prompt = payload[:system] || ""
    
    simulated_response = 
      if String.contains?(system_prompt, "elite Elixir/Python software engineer") do
        """
        {
          "diff": "--- a/lib/dummy.ex\\n+++ b/lib/dummy.ex\\n@@ -1,2 +1,2 @@\\n-defmodule Dummy do\\n+defmodule Dummy do\\n   def test, do: :ok\\n end",
          "explanation": "Applied ADR-01 (functional core) by refactoring the module."
        }
        """
      else
        """
        {
          "capability_name": "Dependency Drift Analyst",
          "capability_type": "cognitive_tool",
          "rationale": "Friction indicates silent failures when upstream APIs change schemas without version bumps. Existing roles only check internal logic, not external contract drift.",
          "trigger_condition": {"touches_external_apis": true, "codebase_age": ">6_months"},
          "implementation_strategy": "Fetch historical API contracts from Institutional Memory and diff against current patch dependencies."
        }
        """
      end
      
    {:ok, simulated_response, 450}
  end

  defp parse_and_validate(raw_json, _schema) do
    case Jason.decode(raw_json) do
      {:ok, map} -> {:ok, map}
      {:error, _} -> {:error, :invalid_json, "LLM failed to produce valid JSON."}
    end
  end
end
