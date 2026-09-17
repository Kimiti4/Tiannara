defmodule Tiannara.Phase10.MEN.NegotiationEngine do
  @moduledoc """
  Core arbitration engine. Computes $\mathcal{N}_{eq}$ and routes to surface allocation or isolation.
  """
  use GenServer
  require Logger

  alias Tiannara.Phase10.MEN.{CompatibilitySurface, ConflictResolver, ConsensusQuorum, LatencyValidator}

  @eq_threshold 0.40
  @max_rounds 15
  @epsilon 1.0e-6

  def start_link(opts), do: GenServer.start_link(__MODULE__, opts, name: __MODULE__)

  @impl true
  def init(opts) do
    {:ok, %{
      conn_name: opts[:connection_name],
      active_negotiations: %{},
      request_queue: :queue.new()
    }}
  end

  @doc "Request arbitration between two partitions"
  @spec request_arbitration(String.t(), String.t(), map()) :: {:ok, String.t()} | {:error, String.t()}
  def request_arbitration(a, b, context), do: GenServer.call(__MODULE__, {:arbitrate, a, b, context})

  @impl true
  def handle_call({:arbitrate, a, b, ctx}, _from, state) do
    neg_id = generate_negotiation_id(a, b)
    new_queue = :queue.in({neg_id, a, b, ctx}, state.request_queue)
    {:reply, {:ok, neg_id}, %{state | request_queue: new_queue}}
  end

  @impl true
  def handle_info(:process_queue, state) do
    case :queue.out(state.request_queue) do
      {{:value, {neg_id, a, b, ctx}}, new_queue} ->
        case run_negotiation_cycle(neg_id, a, b, ctx, 0, state.conn_name) do
          {:ok, surface_id} -> 
            Logger.info("✅ MEN: Compatibility surface #{surface_id} allocated for #{neg_id}")
          {:error, reason} ->
            Logger.warning("🚫 MEN: Negotiation failed for #{neg_id}: #{reason}")
        end
        {:noreply, %{state | request_queue: new_queue}}
      {:empty, _} -> {:noreply, state}
    end
  end

  defp run_negotiation_cycle(neg_id, a, b, ctx, round, conn_name) do
    if round >= @max_rounds, do: {:error, :max_rounds_exceeded}

    # Fetch partition stability & overlap metrics
    {h_a, h_b, s_overlap, d_conflict, c_overhead} = fetch_negotiation_metrics(a, b, ctx)
    
    n_eq = (h_a * h_b * s_overlap) / (d_conflict + c_overhead + @epsilon)
    
    cond do
      n_eq >= @eq_threshold ->
        # Allocate temporary compatibility surface
        CompatibilitySurface.allocate(neg_id, a, b, n_eq, conn_name)
      round < @max_rounds - 1 ->
        # Relax constraints & retry
        ConflictResolver.relax_constraints(a, b, ctx)
        run_negotiation_cycle(neg_id, a, b, ctx, round + 1, conn_name)
      true ->
        {:error, :equilibrium_below_threshold}
    end
  end

  defp fetch_negotiation_metrics(a, b, _ctx) do
    # In production: query Phase 9 MES & Phase 8 RTL telemetry
    # Mock values for structural clarity
    {0.82, 0.75, 0.45, 0.30, 0.15}
  end

  defp generate_negotiation_id(a, b) do
    :crypto.hash(:sha256, "#{a}:#{b}:#{System.system_time()}") |> Base.url_encode64() |> String.slice(0, 16)
  end
end