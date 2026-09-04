defmodule Tiannara.Forecasting.Adapters.WorldModelImpl do
  @moduledoc """
  D2 concrete implementation of `Tiannara.Forecasting.Adapters.WorldModel`.

  Provides the future-state-transition interface to the World Model without
  redesigning it. The Unified Reality Graph remains the canonical world
  representation; EFDI does not fork a parallel world.
  """

  @behaviour Tiannara.Forecasting.Adapters.WorldModel

  alias Tiannara.Forecasting.{Signal}
  alias Tiannara.Forecasting.Adapters.WorldModel

  @impl WorldModel
  @spec ingest_signal(Signal.t()) :: {:ok, term()} | {:error, term()}
  def ingest_signal(%Signal{} = s) do
    {:ok, %{accepted: true, signal_id: s.id, domain: s.domain}}
  end

  @impl WorldModel
  @spec context_for(Signal.t()) :: {:ok, map()} | {:error, term()}
  def context_for(%Signal{domain: domain}) do
    {:ok, %{domain: domain, regime: :unknown}}
  end

  @impl WorldModel
  @spec conflicts_with_world?(Signal.t()) :: {:ok, boolean()} | {:error, term()}
  def conflicts_with_world?(_signal) do
    # Honest: without a live world snapshot D2 cannot assert conflict.
    # Conflicts require existing world-model state (D3+).
    {:error, :world_snapshot_unavailable}
  end
end