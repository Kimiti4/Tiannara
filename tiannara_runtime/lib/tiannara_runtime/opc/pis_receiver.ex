defmodule Tiannara.OPC.PISReceiver do
  @moduledoc """
  Stage 3: OPC PIS Receiver.
  
  The absolute boundary for Python cognition.
  This module strictly ingests and validates the declarative Physics Intent Specification (PIS)
  JSON payload. It rejects ANY payload containing execution semantics or missing
  required resource/budget parameters.
  """
  
  require Logger
  
  @required_keys [
    "intent_id", "category", "domain", "interaction", "target",
    "conservation_enabled", "law_decay", "reversible",
    "observer_signature", "resource_profile", "epistemic_confidence", "description"
  ]
  
  @doc """
  Ingests a raw JSON string from Python and validates its declarative schema.
  Returns `{:ok, pis_map}` or `{:error, reason}`.
  """
  def ingest_payload(json_payload) do
    case Jason.decode(json_payload) do
      {:ok, parsed} -> validate_schema(parsed)
      {:error, _} -> {:error, :invalid_json}
    end
  end
  
  defp validate_schema(parsed) when is_map(parsed) do
    # 1. Verify all required keys are present
    missing_keys = Enum.filter(@required_keys, fn key -> not Map.has_key?(parsed, key) end)
    
    if length(missing_keys) > 0 do
      Logger.warning("[OPC] PIS Ingestion Failed: Missing keys #{inspect(missing_keys)}")
      {:error, {:missing_schema_keys, missing_keys}}
    else
      # 2. Hard check against epistemic confidence threshold
      confidence = parsed["epistemic_confidence"]
      if confidence < 0.3 do
        Logger.warning("[OPC] PIS Ingestion Failed: Epistemic confidence too low (#{confidence})")
        {:error, :epistemic_rejection}
      else
        # 3. Prevent hidden execution instructions in interaction/target fields
        if contains_execution_semantics?(parsed) do
          Logger.error("[OPC] FATAL PIS Ingestion: Execution semantics detected! Attempted AST injection blocked.")
          {:error, :execution_semantics_detected}
        else
          Logger.info("[OPC] PIS Ingestion Successful: Intent #{parsed["intent_id"]} validated.")
          {:ok, parsed}
        end
      end
    end
  end
  
  defp validate_schema(_), do: {:error, :invalid_schema_structure}
  
  defp contains_execution_semantics?(parsed) do
    forbidden = ["apply_force", "tensor", "execute", "mutate", "inject", "ast"]
    
    check_str = String.downcase("#{parsed["interaction"]} #{parsed["target"]} #{parsed["description"]}")
    Enum.any?(forbidden, fn term -> String.contains?(check_str, term) end)
  end
end
