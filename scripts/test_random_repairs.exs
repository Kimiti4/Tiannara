#!/usr/bin/env elixir

# Simple test to verify random number generation for repair success simulation

IO.puts("Testing random number generation for repair simulation...")
IO.puts("=" |> String.duplicate(80))

# Test :rand.uniform() behavior
IO.puts("\nGenerating 20 random numbers:")
for i <- 1..20 do
  rand_val = :rand.uniform()
  status = if rand_val < 0.6, do: "✅ SUCCESS", else: "❌ FAIL"
  IO.puts("  #{i}. #{Float.round(rand_val, 3)} -> #{status}")
end

# Simulate 100 repairs with 60% success rate
IO.puts("\nSimulating 100 repairs with 60% success rate:")
successes = Enum.count(1..100, fn _ -> :rand.uniform() < 0.6 end)
IO.puts("  Successes: #{successes}/100 (#{Float.round(successes / 100 * 100, 1)}%)")

if successes >= 50 do
  IO.puts("\n🎉 Random number generation is working correctly!")
else
  IO.puts("\n⚠️  Warning: Success rate lower than expected")
end
