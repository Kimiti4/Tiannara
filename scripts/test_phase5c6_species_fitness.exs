defmodule Tiannara.ASC.Campaign.Phase5C6Test do
  @moduledoc """
  Phase 5C.6 — Quick Test of Species Fitness & Selection
  
  This test verifies that:
  1. SpeciesFitness module calculates fitness correctly
  2. Adaptive budgets adjust based on fitness
  3. Extinction/dominance detection works
  """

  alias Tiannara.ASC.Crucible.SpeciesFitness
  alias Tiannara.ASC.Crucible.FailureSpecies

  def run_test do
    IO.puts("\n" <> String.duplicate("=", 80))
    IO.puts("🧬 PHASE 5C.6 — SPECIES FITNESS TEST")
    IO.puts(String.duplicate("=", 80))
    
    test_fitness_calculation()
    test_adaptive_budgets()
    test_extinction_detection()
    test_dominance_detection()
    
    IO.puts("\n✅ All Phase 5C.6 tests passed!")
    IO.puts("\nThe architecture is ready for full evolutionary campaigns.")
  end

  defp test_fitness_calculation do
    IO.puts("\n📊 Test 1: Species Fitness Calculation")
    IO.puts(String.duplicate("-", 80))
    
    # Test high-fitness species (good survival, repair, transfer)
    high_fitness_data = %{
      species_id: :concurrency,
      generation: 1,
      births: 100,
      survivals: 80,
      extinctions: 5,
      repairs_attempted: 90,
      repairs_successful: 72,
      transfers_attempted: 50,
      transfers_successful: 40,
      average_recovery_latency_ms: 100.0
    }
    
    high_fitness = SpeciesFitness.calculate_fitness(high_fitness_data)
    
    IO.puts("   High-fitness species (concurrency):")
    IO.puts("     Survival rate: #{Float.round(high_fitness.survival_rate * 100, 1)}%")
    IO.puts("     Repair success: #{Float.round(high_fitness.repair_success_rate * 100, 1)}%")
    IO.puts("     Transfer success: #{Float.round(high_fitness.transfer_success_rate * 100, 1)}%")
    IO.puts("     Overall fitness: #{Float.round(high_fitness.fitness_score, 3)}")
    
    assert high_fitness.fitness_score > 0.5, "High-fitness species should have fitness > 0.5"
    
    # Test low-fitness species (poor survival, repair, transfer)
    low_fitness_data = %{
      species_id: :dependency,
      generation: 1,
      births: 100,
      survivals: 10,
      extinctions: 70,
      repairs_attempted: 90,
      repairs_successful: 5,
      transfers_attempted: 50,
      transfers_successful: 2,
      average_recovery_latency_ms: 5000.0
    }
    
    low_fitness = SpeciesFitness.calculate_fitness(low_fitness_data)
    
    IO.puts("\n   Low-fitness species (dependency):")
    IO.puts("     Survival rate: #{Float.round(low_fitness.survival_rate * 100, 1)}%")
    IO.puts("     Repair success: #{Float.round(low_fitness.repair_success_rate * 100, 1)}%")
    IO.puts("     Transfer success: #{Float.round(low_fitness.transfer_success_rate * 100, 1)}%")
    IO.puts("     Overall fitness: #{Float.round(low_fitness.fitness_score, 3)}")
    
    assert low_fitness.fitness_score < 0.3, "Low-fitness species should have fitness < 0.3"
    
    IO.puts("\n   ✅ Fitness calculation working correctly\n")
  end

  defp test_adaptive_budgets do
    IO.puts("\n💰 Test 2: Adaptive Budget Adjustment")
    IO.puts(String.duplicate("-", 80))
    
    # Initial budgets
    initial_budgets = FailureSpecies.species_budgets()
    
    IO.puts("   Initial budgets:")
    Enum.each(initial_budgets, fn {species, budget} ->
      IO.puts("     #{species}: #{budget}%")
    end)
    
    # Simulate fitness scores (some high, some low)
    fitness_map = %{
      security: 0.85,       # High fitness - should gain budget
      concurrency: 0.80,    # High fitness - should gain budget
      data: 0.60,           # Medium-high fitness
      performance: 0.50,    # Medium fitness
      dependency: 0.10,     # Low fitness - should lose budget
      interface: 0.40,      # Medium-low fitness
      null_safety: 0.05,    # Very low fitness - extinction watch
      boundary: 0.30        # Low-medium fitness
    }
    
    # Adjust budgets
    new_budgets = SpeciesFitness.adjust_budget(initial_budgets, fitness_map)
    
    IO.puts("\n   Adjusted budgets (after selection pressure):")
    Enum.each(new_budgets, fn {species, budget} ->
      old_budget = Map.get(initial_budgets, species, 0)
      change = budget - old_budget
      change_str = if change >= 0, do: "+#{Float.round(change, 1)}", else: "#{Float.round(change, 1)}"
      IO.puts("     #{species}: #{Float.round(budget, 1)}% (#{change_str})")
    end)
    
    # Verify constraints
    min_budget = Map.values(new_budgets) |> Enum.min()
    max_budget = Map.values(new_budgets) |> Enum.max()
    
    assert min_budget >= 5.0, "Minimum budget constraint violated: #{min_budget}"
    assert max_budget <= 35.0, "Maximum budget constraint violated: #{max_budget}"
    
    # Verify high-fitness species gained budget
    assert new_budgets.security > initial_budgets.security, "High-fitness security should gain budget"
    assert new_budgets.concurrency > initial_budgets.concurrency, "High-fitness concurrency should gain budget"
    
    # Verify low-fitness species lost budget
    assert new_budgets.dependency < initial_budgets.dependency, "Low-fitness dependency should lose budget"
    
    IO.puts("\n   ✅ Adaptive budgets working correctly\n")
  end

  defp test_extinction_detection do
    IO.puts("\n☠️  Test 3: Extinction Detection")
    IO.puts(String.duplicate("-", 80))
    
    fitness_map = %{
      security: 0.85,
      concurrency: 0.80,
      data: 0.60,
      performance: 0.50,
      dependency: 0.10,
      interface: 0.40,
      null_safety: 0.03,    # Below 0.05 threshold - extinction watch
      boundary: 0.30
    }
    
    extinction_watch = SpeciesFitness.get_extinction_watch_species(fitness_map)
    
    IO.puts("   Species on extinction watch (fitness < 0.05):")
    Enum.each(extinction_watch, fn {species, fitness} ->
      IO.puts("     ⚠️  #{species}: #{Float.round(fitness, 3)}")
    end)
    
    assert length(extinction_watch) > 0, "Should detect at least one species on extinction watch"
    assert Keyword.has_key?(extinction_watch, :null_safety), "null_safety should be on extinction watch"
    
    IO.puts("\n   ✅ Extinction detection working correctly\n")
  end

  defp test_dominance_detection do
    IO.puts("\n👑 Test 4: Dominance Detection")
    IO.puts(String.duplicate("-", 80))
    
    fitness_map = %{
      security: 0.85,       # Above 0.75 threshold - dominant
      concurrency: 0.80,    # Above 0.75 threshold - dominant
      data: 0.60,
      performance: 0.50,
      dependency: 0.10,
      interface: 0.40,
      null_safety: 0.03,
      boundary: 0.30
    }
    
    {dominant_species, dominant_fitness} = SpeciesFitness.get_dominant_species(fitness_map)
    
    IO.puts("   Dominant species (highest fitness):")
    IO.puts("     👑 #{dominant_species}: #{Float.round(dominant_fitness, 3)}")
    
    assert dominant_fitness > 0.75, "Dominant species should have fitness > 0.75"
    
    # Check status classification
    dominant_status = SpeciesFitness.determine_status(%{fitness_score: dominant_fitness})
    assert dominant_status == :dominant, "Dominant species should have :dominant status"
    
    IO.puts("     Status: #{dominant_status}")
    
    IO.puts("\n   ✅ Dominance detection working correctly\n")
  end

  defp assert(condition, message) do
    unless condition do
      raise AssertionError, message: message
    end
  end

  defmodule AssertionError do
    defexception [:message]
  end
end

# Run test
Tiannara.ASC.Campaign.Phase5C6Test.run_test()
