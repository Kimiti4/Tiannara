defmodule Tiannara.AAL.BlueprintValidator do
  @moduledoc """
  Structural validation for extracted blueprints.

  Passing this validator establishes only that a blueprint has the expected
  shape and Verilog module delimiters. It does not certify semantic correctness,
  synthesis, simulation, or hardware safety.
  """

  require Logger

  @minimum_confidence 0.85

  @doc "Return only structurally valid successful blueprints."
  @spec validate([map()]) :: [map()]
  def validate(blueprints) when is_list(blueprints) do
    Enum.filter(blueprints, &valid_blueprint?/1)
  end

  def validate(_), do: []

  defp valid_blueprint?(%{
         status: :success,
         domain: domain,
         schematics: schematics,
         confidence: confidence
       })
       when (is_atom(domain) or is_binary(domain)) and is_binary(schematics) and
              is_number(confidence) and confidence >= @minimum_confidence and confidence <= 1 do
    has_module_def = String.contains?(schematics, "module ")
    has_endmodule = String.contains?(schematics, "endmodule")

    if has_module_def and has_endmodule do
      true
    else
      Logger.warning("Blueprint rejected: malformed Verilog module structure.")
      false
    end
  end

  defp valid_blueprint?(%{status: :failed, reason: reason}) do
    Logger.warning("Blueprint extraction failed: #{inspect(reason)}")
    false
  end

  defp valid_blueprint?(_blueprint) do
    Logger.warning("Blueprint rejected: missing fields or invalid confidence/type.")
    false
  end
end
