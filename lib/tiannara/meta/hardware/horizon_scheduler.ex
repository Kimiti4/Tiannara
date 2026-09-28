defmodule Tiannara.Meta.Hardware.HorizonScheduler do
  @moduledoc """
  Deterministic EHTC router using observed queue depth and fail-closed
  backpressure. The scheduler is an accelerator abstraction, not a claim of
  physically unbounded compute.
  """
  use GenServer

  def start_link(opts), do: GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  def route_payload(payload), do: GenServer.call(__MODULE__, {:route, payload})

  def compute_principal_eigenvectors(tensor, components, opts \\ []) do
    execute(:principal_eigenvectors, {tensor, components}, opts)
  end

  def execute(operation, payload, opts \\ []) do
    GenServer.call(__MODULE__, {:execute, operation, payload, opts},
      Keyword.get(opts, :timeout, 30_000) + 1_000)
  catch
    :exit, reason -> {:error, {:scheduler_exit, reason}}
  end

  @impl true
  def init(opts) do
    {:ok, %{hsv_pool: Keyword.get(opts, :hsv_pool, [:hsv_alpha, :hsv_beta, :hsv_gamma])}}
  end

  @impl true
  def handle_call({:route, payload}, _from, state), do: {:reply, route(state.hsv_pool, payload), state}

  @impl true
  def handle_call({:execute, operation, payload, opts}, _from, state) do
    result =
      case choose_core(state.hsv_pool) do
        {:ok, core_id} -> Tiannara.Meta.Hardware.EventHorizonTensorCore.compute(core_id, operation, payload, opts)
        error -> error
      end
    {:reply, result, state}
  end

  defp route([], _payload), do: {:error, :total_saturation}
  defp route(pool, payload) do
    case choose_core(pool) do
      {:ok, core_id} ->
        case Tiannara.Meta.Hardware.EventHorizonTensorCore.submit_payload(core_id, payload) do
          :accepted -> {:ok, core_id}
          error -> error
        end
      error -> error
    end
  end

  defp choose_core(pool) do
    candidates =
      Enum.flat_map(pool, fn core_id ->
        case Tiannara.Meta.Hardware.EventHorizonTensorCore.stats(core_id) do
          {:ok, stats} -> [{stats.queue_depth, core_id}]
          _ -> []
        end
      end)

    case Enum.sort_by(candidates, &elem(&1, 0)) do
      [{depth, core_id} | _] when depth < 10_000 -> {:ok, core_id}
      [] -> {:error, :no_available_ehtc_core}
      _ -> {:error, :total_saturation}
    end
  end
end
