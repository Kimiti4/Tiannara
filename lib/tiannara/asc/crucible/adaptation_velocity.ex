defmodule Tiannara.ASC.Crucible.AdaptationVelocity do
  @moduledoc """
  Adaptation Velocity — tracks fitness gain per generation to measure evolutionary progress.

  Measures whether engineering knowledge is accumulating and improving over time by tracking:
  - Average repair success rate per generation
  - Knowledge reuse rate per generation
  - Transfer success rate per generation
  - Overall adaptation velocity (fitness gain / generation)

  ## Metrics

  Adaptation Velocity > 0 means the system is learning and improving.
  Adaptation Velocity = 0 means stagnation.
  Adaptation Velocity < 0 means degradation.

  ## Exit Criteria (Phase 5)

  Target: Adaptation Velocity > 0 for at least one lineage

  """

  use GenServer

  @typedoc "Generation fitness snapshot"
  @type generation_snapshot :: %{
          generation: non_neg_integer(),
          avg_success_rate: float(),
          knowledge_reuse_rate: float(),
          transfer_success_rate: float(),
          composite_fitness: float(),
          timestamp: DateTime.t()
        }

  # State
  defstruct [
    snapshots: [],           # List of generation_snapshot maps
    baseline_fitness: nil,   # Fitness at generation 0
    current_generation: 0
  ]

  @doc """
  Start the Adaptation Velocity tracker.
  """
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, %__MODULE__{}, Keyword.merge(opts, [name: __MODULE__]))
  end

  @impl true
  def init(_opts) do
    IO.puts("✅ Adaptation Velocity tracker initialized")
    {:ok, %__MODULE__{}}
  end

  @doc """
  Record a generation snapshot with current fitness metrics.

  ## Parameters

  - `generation` - Current generation number
  - `metrics` - Map containing current performance metrics

  ## Example

      iex> AdaptationVelocity.record_generation(1, %{
      ...>   avg_success_rate: 0.25,
      ...>   knowledge_reuse_rate: 0.15,
      ...>   transfer_success_rate: 0.10
      ...> })

  """
  def record_generation(generation, metrics) do
    GenServer.cast(__MODULE__, {:record_generation, generation, metrics})
  end

  @impl true
  def handle_cast({:record_generation, generation, metrics}, state) do
    # Calculate composite fitness score
    composite_fitness = calculate_composite_fitness(metrics)

    snapshot = %{
      generation: generation,
      avg_success_rate: Map.get(metrics, :avg_success_rate, 0.0),
      knowledge_reuse_rate: Map.get(metrics, :knowledge_reuse_rate, 0.0),
      transfer_success_rate: Map.get(metrics, :transfer_success_rate, 0.0),
      composite_fitness: composite_fitness,
      timestamp: DateTime.utc_now()
    }

    # Store baseline on first generation
    new_state =
      if state.baseline_fitness == nil do
        IO.puts("📊 [AdaptationVelocity] Baseline fitness at generation #{generation}: #{Float.round(composite_fitness * 100, 2)}%")
        %{state | baseline_fitness: composite_fitness, current_generation: generation}
      else
        state
      end

    # Add snapshot and keep last 100 generations for efficiency
    updated_snapshots = [snapshot | new_state.snapshots] |> Enum.take(100)

    # Calculate and log adaptation velocity
    velocity = calculate_adaptation_velocity(updated_snapshots)

    if rem(generation, 10) == 0 or velocity != 0.0 do
      IO.puts("📈 [AdaptationVelocity] Generation #{generation}:")
      IO.puts("   Composite Fitness: #{Float.round(composite_fitness * 100, 2)}%")
      IO.puts("   Adaptation Velocity: #{Float.round(velocity * 100, 3)}% per generation")

      if velocity > 0 do
        IO.puts("   ✅ System is IMPROVING (positive adaptation)")
      else
        IO.puts("   ⚠️  System is STAGNATING or DEGRADING")
      end
    end

    {:noreply, %{new_state | snapshots: updated_snapshots, current_generation: generation}}
  end

  @doc """
  Get current adaptation velocity.

  ## Returns

  - Float representing fitness change per generation
  - Positive = improving, Negative = degrading, Zero = stagnant

  """
  def get_adaptation_velocity do
    GenServer.call(__MODULE__, :get_adaptation_velocity)
  end

  @impl true
  def handle_call(:get_adaptation_velocity, _from, state) do
    velocity = calculate_adaptation_velocity(state.snapshots)
    {:reply, velocity, state}
  end

  @impl true
  def handle_call(:get_snapshots, _from, state) do
    {:reply, Enum.reverse(state.snapshots), state}
  end

  @impl true
  def handle_call(:get_summary, _from, state) do
    snapshots = Enum.reverse(state.snapshots)

    summary =
      if length(snapshots) >= 2 do
        first = hd(snapshots)
        last = List.last(snapshots)

        generations_span = last.generation - first.generation
        fitness_gain = last.composite_fitness - first.composite_fitness

        velocity =
          if generations_span > 0 do
            fitness_gain / generations_span
          else
            0.0
          end

        %{
          total_generations: length(snapshots),
          first_generation: first.generation,
          last_generation: last.generation,
          baseline_fitness: first.composite_fitness,
          current_fitness: last.composite_fitness,
          total_fitness_gain: fitness_gain,
          adaptation_velocity: velocity,
          trend: determine_trend(velocity)
        }
      else
        %{
          total_generations: length(snapshots),
          message: "Insufficient data for velocity calculation (need ≥2 generations)"
        }
      end

    {:reply, summary, state}
  end

  @doc """
  Get all recorded generation snapshots.
  """
  def get_snapshots do
    GenServer.call(__MODULE__, :get_snapshots)
  end

  @doc """
  Get summary statistics.
  """
  def get_summary do
    GenServer.call(__MODULE__, :get_summary)
  end

  # Private helpers

  defp calculate_composite_fitness(metrics) do
    # Weighted composite of key metrics
    # Success Rate: 40%, Reuse Rate: 35%, Transfer Rate: 25%
    success_weight = 0.40
    reuse_weight = 0.35
    transfer_weight = 0.25

    success_rate = Map.get(metrics, :avg_success_rate, 0.0)
    reuse_rate = Map.get(metrics, :knowledge_reuse_rate, 0.0)
    transfer_rate = Map.get(metrics, :transfer_success_rate, 0.0)

    (success_rate * success_weight) +
      (reuse_rate * reuse_weight) +
      (transfer_rate * transfer_weight)
  end

  defp calculate_adaptation_velocity(snapshots) do
    # Need at least 2 snapshots to calculate velocity
    if length(snapshots) < 2 do
      0.0
    else
      # Sort by generation
      sorted = Enum.sort_by(snapshots, & &1.generation)

      # Use linear regression for more robust velocity estimate
      # For simplicity, use first and last snapshot
      first = hd(sorted)
      last = List.last(sorted)

      generation_diff = last.generation - first.generation

      if generation_diff > 0 do
        fitness_diff = last.composite_fitness - first.composite_fitness
        fitness_diff / generation_diff
      else
        0.0
      end
    end
  end

  defp determine_trend(velocity) do
    cond do
      velocity > 0.01 -> :improving
      velocity < -0.01 -> :degrading
      true -> :stagnant
    end
  end
end
