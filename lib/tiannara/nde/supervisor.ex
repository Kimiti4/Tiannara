defmodule Tiannara.NDE.Supervisor do
  use GenServer
  require Logger

  def start_link(_), do: GenServer.start_link(__MODULE__, %{}, name: __MODULE__)

  def init(_) do
    # Schedule periodic ecology checks
    Process.send_after(self(), :evaluate_ecology, 5000)
    {:ok, %{last_pressure: 0.0}}
  end

  def handle_info(:evaluate_ecology, state) do
    # Fetch ecology from D2 Analytics Engine
    health = Tiannara.Sentinel.D2.AnalyticsEngine.certify_ecosystem_health()
    
    # Map DiversityProfile to the format expected by NDE Convergence
    ecology = %{
      semantic_entropy: health.diversity_profile.species_entropy,
      compressed_density: health.diversity_profile.attractor_concentration,
      lineages: [], # Mocked for now
      niches: []    # Mocked for now
    }

    case Tiannara.NDE.Convergence.evaluate(ecology) do
      {:inject, pressure} ->
        # Send intervention request through IRD to prevent resonance cascade
        Tiannara.IRD.Supervisor.propose_intervention(__MODULE__, :inject_novelty, pressure * 10)
        
        # In a real environment, IRD would callback to execute this.
        # For simulation, we assume it's approved eventually.
        Tiannara.NDE.Novelty.inject(ecology, pressure)
        
        Process.send_after(self(), :evaluate_ecology, 5000)
        {:noreply, %{state | last_pressure: pressure}}

      {:stable, _pressure} ->
        Process.send_after(self(), :evaluate_ecology, 5000)
        {:noreply, state}
    end
  end
end
