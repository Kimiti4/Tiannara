defmodule Tiannara.HSV.VentPool do
  @moduledoc """
  DynamicSupervisor managing a warm pool of SingularityVent workers.
  Keeps a configurable number of pre‑initialized workers for low‑latency activation.
  """
  use DynamicSupervisor

  @warm_pool_size 2

  def start_link(_opts) do
    DynamicSupervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  @impl true
  def init(_args) do
    # One_for_one strategy; workers are independent.
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  @doc """
  Pre‑populate the pool with a few SingularityVent workers.
  """
  def populate_pool do
    Enum.each(1..@warm_pool_size, fn _ ->
      start_worker()
    end)
  end

  @doc """
  Start a new SingularityVent worker on demand (lazy).
  """
  def start_worker do
    spec = {Tiannara.Bridge.SingularityVent, []}
    DynamicSupervisor.start_child(__MODULE__, spec)
  end
end
