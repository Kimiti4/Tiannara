defmodule Tiannara.SOPL.ShadowValidator do
  @moduledoc """
  SOPL-2: Shadow Validator
  
  Evaluates mutated laws in a zero-cost shadow simulation before deployment.
  Computes a `%ConstitutionalPressure{}` budget instead of a binary pass/fail.
  """
  require Logger
  alias Tiannara.SOPL.ConstitutionalPressure

  @doc """
  Runs the mutated children through a fast-forward shadow evaluation.
  Filters out laws that violate the Constitution or have extreme pressure.
  Returns a list sorted by safety (lowest pressure first).
  """
  def validate(mutated_laws) do
    Logger.info("🌌 [SOPL-2 Shadow Validator] Validating #{length(mutated_laws)} child laws...")

    validated = 
      mutated_laws
      |> Enum.map(&shadow_evaluate/1)
      |> Enum.reject(fn {status, _law, _pressure} -> status == :violation end)
      |> Enum.sort_by(fn {:ok, _law, pressure} -> pressure.total_pressure end, :asc)
      
    Logger.info("✅ [SOPL-2 Shadow Validator] #{length(validated)} / #{length(mutated_laws)} passed.")
    validated
  end

  defp shadow_evaluate(law) do
    # In a full simulation, this runs 100 fast-epochs in a shadow shard.
    # Here we calculate the pressure mathematically based on parameter strain.
    
    # Pressure 0.0 -> Safe. Pressure 1.0 -> Violation.
    rc = if Map.get(law.fitness_weights, :empirical_grounding, 1.0) < 0.1, do: 0.9, else: 0.1
    
    # Causal Consistency: Too much tolerance risks paradoxes
    cc = if Map.get(law.extinction_model, :causal_tolerance, 0.1) > 0.8, do: 0.95, else: 0.2
    
    # Identity Continuity: Too low risks timeline detachment
    ic = if Map.get(law.trust_formula, :identity_persistence_weight, 0.5) < 0.2, do: 0.8, else: 0.1
    
    # Conservation: Creating energy from nothing
    con = if law.novelty_reward > Map.get(law.fitness_weights, :economic_cap, 5000.0), do: 1.0, else: 0.3
    
    # Observer Accountability
    acc = 0.0 # Handled structurally by ECL
    
    # Evolutionary Openness: Pressure rises if mutation pressure or diversity floors are near 0
    op_mut = if law.mutation_pressure < 0.01, do: 0.9, else: 0.1
    op_div = if law.diversity_floor < 0.1, do: 0.8, else: 0.2
    op = (op_mut + op_div) / 2.0

    total = (rc + cc + ic + con + acc + op) / 6.0
    
    pressure = %ConstitutionalPressure{
      reality_contact: rc,
      causal_consistency: cc,
      identity_continuity: ic,
      conservation: con,
      accountability: acc,
      openness: op,
      total_pressure: total
    }

    # Update the law's internal margin metric to match the exact pressure
    updated_law = %{law | constitutional_margin: 1.0 - total}

    if cc >= 1.0 or con >= 1.0 or op >= 1.0 or total > 0.85 do
      Logger.warning("❌ [Shadow Validator] Law #{law.id} aborted (Invariant Violation).")
      {:violation, updated_law, pressure}
    else
      {:ok, updated_law, pressure}
    end
  end
end
