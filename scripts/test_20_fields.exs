defmodule Tiannara.Diagnostics.Fields20 do
  require Logger

  def run do
    epoch = 0

    # Start required services
    Application.ensure_all_started(:tiannara)
    if Process.whereis(Tiannara.REA.LineageRegistry) == nil do
      Tiannara.REA.LineageRegistry.start_link()
    end

    # 1. Define two different worlds
    med_env = %Tiannara.REA.EvolutionaryEnvironment{
      resources: %{resource_ceiling: 100, compute_ceiling: 100},
      pressures: %{minimum_viability: 0.1},
      specialization_bias: %{medicine: 2.0, engineering: 0.1, robotics: 0.1}
    }

    eng_env = %Tiannara.REA.EvolutionaryEnvironment{
      resources: %{resource_ceiling: 100, compute_ceiling: 100},
      pressures: %{minimum_viability: 0.1},
      specialization_bias: %{engineering: 2.0, robotics: 2.0, medicine: 0.1}
    }

    niche = %{fitness_weights: %{economy: 0.3, truth: 0.4, cohesion: 0.3}}

    # 2. Spawn seed civilizations
    med_civ = Tiannara.Ecology.Civilization.spawn(epoch, niche, %{})
    eng_civ = Tiannara.Ecology.Civilization.spawn(epoch, niche, %{})

    # 3. Fast-forward 100 epochs independently
    final_med = Enum.reduce(1..100, med_civ, fn e, civ -> 
      # Mock the tick cycle: mutate and receive basic pressure
      mutated = Tiannara.Ecology.Civilization.mutate(civ, med_env)
      Tiannara.Ecology.Civilization.receive_pressure(mutated, %{})
    end)

    final_eng = Enum.reduce(1..100, eng_civ, fn e, civ -> 
      mutated = Tiannara.Ecology.Civilization.mutate(civ, eng_env)
      Tiannara.Ecology.Civilization.receive_pressure(mutated, %{})
    end)

    # 4. Compare Divergence
    IO.puts("\n=== ASYMMETRICAL OPTIMIZATION DIVERGENCE TEST ===")
    IO.puts("Epochs: 100")
    IO.puts("\n🌍 WORLD A: Medicine-Biased")
    IO.puts("Medicine Aptitude: #{Float.round(final_med.domain_aptitudes.medicine, 4)}")
    IO.puts("Engineering Aptitude: #{Float.round(final_med.domain_aptitudes.engineering, 4)}")
    IO.puts("Robotics Aptitude: #{Float.round(final_med.domain_aptitudes.robotics, 4)}")
    
    IO.puts("\n🌍 WORLD B: Engineering-Biased")
    IO.puts("Medicine Aptitude: #{Float.round(final_eng.domain_aptitudes.medicine, 4)}")
    IO.puts("Engineering Aptitude: #{Float.round(final_eng.domain_aptitudes.engineering, 4)}")
    IO.puts("Robotics Aptitude: #{Float.round(final_eng.domain_aptitudes.robotics, 4)}")

    # Verify both worlds still contain all 20 fields natively
    med_fields = Map.keys(final_med.domain_aptitudes) |> length()
    eng_fields = Map.keys(final_eng.domain_aptitudes) |> length()

    IO.puts("\nCapability Completeness:")
    IO.puts("World A Tracking #{med_fields}/20 domains.")
    IO.puts("World B Tracking #{eng_fields}/20 domains.")
  end
end

Tiannara.Diagnostics.Fields20.run()
