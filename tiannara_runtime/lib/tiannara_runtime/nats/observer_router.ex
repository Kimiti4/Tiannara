defmodule Tiannara.Meta.Mesh.ObserverRouter do
  @moduledoc """
  Phase 5F.x — Observer Entropy Router

  Routes observer events to appropriate entropy zones based on
  divergence metrics, paradox density, and causal stability.

  ## Entropy Zones

  - `:high` — High divergence, frequent branching, unstable physics
  - `:medium` — Moderate divergence, occasional forks
  - `:low` — Stable observers, consistent reality manifolds

  ## Routing Strategy

  Observers are routed based on:
  - Current entropy score (0.0-1.0)
  - Branching frequency (branches per minute)
  - Paradox density (contradictions per chronogram sector)
  - MSCL pressure level

  ## Usage

      # Route observer to entropy zone
      ObserverRouter.route_observer("obs_001", %{
        entropy: 0.75,
        branch_rate: 5.2,
        paradox_density: 0.3
      })
  """

  use GenServer
  require Logger

  alias Tiannara.Meta.Mesh.RealityBus

  # Entropy thresholds
  @high_entropy_threshold 0.6
  @medium_entropy_threshold 0.3

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc """
  Routes an observer event to the appropriate entropy zone.

  ## Parameters
  - `observer_id`: Observer identifier
  - `metrics`: Map with entropy, branch_rate, paradox_density

  ## Returns
  - `:ok` on successful routing

  ## Example

      ObserverRouter.route_observer("obs_001", %{
        entropy: 0.75,
        branch_rate: 5.2
      })
  """
  def route_observer(observer_id, metrics) do
    GenServer.cast(__MODULE__, {:route, observer_id, metrics})
  end

  @doc """
  Determines entropy zone from metrics.

  ## Parameters
  - `metrics`: Observer metrics map

  ## Returns
  - `:high`, `:medium`, or `:low`

  ## Example

      zone = ObserverRouter.classify_entropy(%{entropy: 0.8})
      # Returns: :high
  """
  def classify_entropy(metrics) do
    with {:ok, entropy_score} <- calculate_entropy_score(metrics) do
      cond do
        entropy_score > @high_entropy_threshold -> :high
        entropy_score > @medium_entropy_threshold -> :medium
        true -> :low
      end
    end
  end

  # ── GenServer Callbacks ───────────────────────────────────────────────────

  @impl true
  def init(_opts) do
    state = %{
      observer_zones: %{},  # %{observer_id => entropy_zone}
      routing_count: 0
    }

    Logger.info("🧭 [ObserverRouter] Initialized entropy-based routing")
    {:ok, state}
  end

  @impl true
  def handle_cast({:route, observer_id, metrics}, state) do
    case classify_entropy(metrics) do
      zone when zone in [:high, :medium, :low] ->
        RealityBus.publish_partitioned("observer.activity", %{
          observer_id: observer_id,
          metrics: metrics,
          zone: zone
        }, zone)

        new_zones = Map.put(state.observer_zones, observer_id, zone)
        Logger.debug("🧭 [ObserverRouter] Routed #{observer_id} to #{zone} entropy zone")

        {:noreply, %{state |
          observer_zones: new_zones,
          routing_count: state.routing_count + 1
        }}

      {:error, reason} ->
        Logger.warning("🧭 [ObserverRouter] Rejected incomplete observer metrics: #{inspect(reason)}")
        {:noreply, state}
    end
  end

  # ── Private Functions ─────────────────────────────────────────────────────

  defp calculate_entropy_score(metrics) do
    with {:ok, entropy} <- required_metric(metrics, :entropy),
         {:ok, branch_rate} <- required_metric(metrics, :branch_rate),
         {:ok, paradox_density} <- required_metric(metrics, :paradox_density),
         {:ok, mscl_pressure} <- required_metric(metrics, :mscl_pressure) do
      normalized_branch_rate = min(branch_rate / 10.0, 1.0)
      {:ok, (entropy * 0.4) + (normalized_branch_rate * 0.3) + (paradox_density * 0.2) + (mscl_pressure * 0.1)}
    else
      {:error, reason} -> {:error, {:missing_observer_metric, reason}}
    end
  end

  defp required_metric(metrics, key) do
    case Map.get(metrics, key, Map.get(metrics, Atom.to_string(key))) do
      value when is_number(value) -> {:ok, value / 1.0}
      _ -> {:error, key}
    end
  end
end
