defmodule Tiannara.AAL.BlueprintValidator do
  @moduledoc """
  Hard validation layer ensuring hallucinated or structurally invalid blueprints 
  are rejected before hitting Base Reality.
  """
  require Logger

  @doc """
  Filters a list of blueprints, returning only those that pass structural validation.
  """
  @spec validate([map()]) :: [map()]
  def validate(blueprints) do
    Enum.filter(blueprints, &valid_blueprint?/1)
  end

  defp valid_blueprint?(%{status: :failed}) do
    false
  end

  defp valid_blueprint?(%{schematics: schematics, confidence: confidence}) do
    # Validate structural safety and logical thresholds
    has_module_def = String.contains?(schematics, "module ")
    has_endmodule = String.contains?(schematics, "endmodule")
    high_confidence = confidence > 0.85

    if not has_module_def or not has_endmodule do
      Logger.warning("❌ Blueprint rejected: Malformed Verilog structure.")
      false
    else
      if not high_confidence do
        Logger.warning("❌ Blueprint rejected: Confidence score below threshold (#{confidence}).")
        false
      else
        true
      end
    end
  end

  defp valid_blueprint?(_), do: false
end
