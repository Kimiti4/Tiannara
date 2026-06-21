defmodule Tiannara.ASC.Crucible.FailureSynthesizer do
  @moduledoc """
  Generates high-entropy synthetic failures to force the discovery 
  of novel repair patterns. Entropy scales with generation to prevent 
  the system from just rediscovering early, simple patterns.
  """
  
  @domains [:compute, :network, :storage, :memory, :concurrency, :dependency, :security]
  @topologies [:mesh, :star, :ring, :tree, :chaos]
  @constraints [:latency, :throughput, :memory_limit, :cpu_quota, :fault_tolerance]
  
  def generate(generation) do
    # Entropy scales up to generation 50, then maxes out
    entropy_factor = min(1.0, generation / 50.0)
    
    %{
      id: "syn_fail_#{generation}_#{:erlang.unique_integer([:positive])}",
      domain: Enum.random(@domains),
      topology: Enum.random(@topologies),
      severity: :rand.uniform() * entropy_factor,
      constraints: generate_constraints(entropy_factor),
      timestamp: System.system_time(:millisecond)
    }
  end
  
  defp generate_constraints(entropy) do
    count = trunc(entropy * 3) + 1
    Enum.map(1..count, fn _ -> Enum.random(@constraints) end)
    |> Enum.uniq()
  end
end
