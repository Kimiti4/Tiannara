defmodule TiannaraRuntime.CIS.EntropyMonitor do
  @moduledoc """
  ARCHITECTURAL BREAKTHROUGH v20: CIS Entropy Monitor
  
  Monitors Shannon diversity entropy across the identity population.
  
  Central ecological health metric from GRCC v10 specification:
  H = -Σ p_i * log(p_i)
  
  Where p_i is lineage population share.
  
  Target Range:
  - <0.35: Monoculture risk (CRITICAL)
  - 0.35-0.55: AT_RISK
  - 0.60-0.75: HEALTHY
  - >0.85: Chaotic fragmentation
  
  This GenServer periodically samples the identity population and computes
  entropy to detect collapse attractors before they cause ecosystem failure.
  """
  
  use GenServer
  
  # Configuration from GRCC v10 spec
  @target_entropy_min 0.60
  @target_entropy_max 0.75
  @critical_threshold 0.35
  @at_risk_threshold 0.55
  
  # Client API
  
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end
  
  @doc """
  Get current entropy measurement and ecosystem health status.
  """
  def get_entropy_status() do
    GenServer.call(__MODULE__, :get_entropy_status)
  end
  
  @doc """
  Manually trigger entropy calculation.
  """
  def calculate_entropy_now() do
    GenServer.cast(__MODULE__, :calculate_entropy)
  end
  
  # Server Callbacks
  
  @impl true
  def init(_opts) do
    state = %{
      current_entropy: 0.0,
      health_status: :unknown,
      history: [],
      last_calculation: nil,
      monitoring_interval: :timer.seconds(5)  # Check every 5 seconds
    }
    
    # Start periodic monitoring
    schedule_calculation(state.monitoring_interval)
    
    {:ok, state}
  end
  
  @impl true
  def handle_call(:get_entropy_status, _from, state) do
    {:reply, %{
      entropy: state.current_entropy,
      status: state.health_status,
      target_range: {@target_entropy_min, @target_entropy_max},
      history_length: length(state.history)
    }, state}
  end
  
  @impl true
  def handle_cast(:calculate_entropy, state) do
    new_state = perform_entropy_calculation(state)
    {:ok, new_state}
  end
  
  @impl true
  def handle_info(:calculate_entropy, state) do
    new_state = perform_entropy_calculation(state)
    schedule_calculation(new_state.monitoring_interval)
    {:ok, new_state}
  end
  
  # Private Functions
  
  defp perform_entropy_calculation(state) do
    # Query identity registry for population distribution
    lineage_distribution = get_lineage_distribution()
    
    # Calculate Shannon entropy
    entropy = calculate_shannon_entropy(lineage_distribution)
    
    # Determine health status
    health_status = classify_health(entropy)
    
    # Log if status changed
    if health_status != state.health_status do
      IO.puts("🛡️ CIS Entropy Alert: #{state.health_status} → #{health_status} (H=#{Float.round(entropy, 3)})")
    end
    
    # Update history (keep last 100 measurements)
    history = [%{
      timestamp: System.system_time(:millisecond),
      entropy: entropy,
      status: health_status,
      distribution: lineage_distribution
    } | state.history] |> Enum.take(100)
    
    %{state | 
      current_entropy: entropy,
      health_status: health_status,
      history: history,
      last_calculation: DateTime.utc_now()
    }
  end
  
  defp get_lineage_distribution() do
    # In production, this would query the IdentityRegistry
    # For Phase 1, we'll simulate with a placeholder
    # TODO: Integrate with actual identity process registry
    
    # Simulated distribution - replace with actual registry query
    %{
      "lineage_1" => 40,
      "lineage_2" => 30,
      "lineage_3" => 20,
      "lineage_4" => 10
    }
  end
  
  defp calculate_shannon_entropy(distribution) do
    total = Map.values(distribution) |> Enum.sum()
    
    if total == 0 do
      0.0
    else
      distribution
      |> Map.values()
      |> Enum.map(fn count -> count / total end)
      |> Enum.map(fn p -> if p > 0, do: -p * :math.log(p), else: 0 end)
      |> Enum.sum()
      |> normalize_entropy(length(Map.keys(distribution)))
    end
  end
  
  defp normalize_entropy(entropy, num_categories) do
    # Normalize to [0, 1] range by dividing by max possible entropy (log(n))
    max_entropy = :math.log(num_categories)
    if max_entropy > 0 do
      entropy / max_entropy
    else
      0.0
    end
  end
  
  defp classify_health(entropy) do
    cond do
      entropy < @critical_threshold -> :critical
      entropy < @at_risk_threshold -> :at_risk
      entropy >= @target_entropy_min && entropy <= @target_entropy_max -> :healthy
      entropy > @target_entropy_max -> :chaotic
      true -> :at_risk
    end
  end
  
  defp schedule_calculation(interval) do
    Process.send_after(self(), :calculate_entropy, interval)
  end
end
