defmodule Tiannara.Phase14.Formal.ContractionVerifier do
  @moduledoc """
  Runtime Banach Fixed-Point Verification Engine.
  Computes empirical Lipschitz constant $\hat{k}$ over generation history.
  Triggers divergence containment if $\hat{k} \geq 0.99$.
  """
  use GenServer
  require Logger

  @convergence_threshold 0.85
  @divergence_threshold 0.99
  @window_size 10
  @lambda_weight 0.3

  def start_link(opts \\ []), do: GenServer.start_link(__MODULE__, opts, name: __MODULE__)

  @impl true
  def init(_opts) do
    {:ok, %{history: :queue.new(), last_k: 1.0}}
  end

  @doc "Record generation step & compute contraction coefficient"
  @spec record_step(axiom_a :: map(), axiom_b :: map(), consistency_a :: float(), consistency_b :: float()) :: 
    {:convergent, float()} | {:divergent, float()} | :insufficient_history
  def record_step(a, b, ca, cb), do: GenServer.call(__MODULE__, {:step, a, b, ca, cb})

  @impl true
  def handle_call({:step, a, b, ca, cb}, _from, state) do
    distance = compute_metric_distance(a, b, ca, cb)
    new_history = :queue.in(distance, state.history)
    trimmed = if :queue.len(new_history) > @window_size, do: :queue.drop(new_history), else: new_history
    
    k = compute_lipschitz(trimmed)
    
    result = cond do
      :queue.len(trimmed) < 3 -> :insufficient_history
      k < @convergence_threshold -> {:convergent, k}
      k >= @divergence_threshold -> {:divergent, k}
      true -> :stable
    end
    
    Logger.debug("📐 REG Contraction: k=#{Float.round(k, 3)} -> #{inspect(result)}")
    :telemetry.execute([:tiannara, :phase14, :reg, :contraction], %{k: k}, %{})
    
    {:reply, result, %{state | history: trimmed, last_k: k}}
  end

  defp compute_metric_distance(a, b, ca, cb) do
    # Simplified L2 norm of drift + consistency delta
    drift = compute_drift_norm(a, b)
    consistency_diff = abs(ca - cb)
    drift + (@lambda_weight * consistency_diff)
  end

  defp compute_drift_norm(a, b) do
    keys = Map.keys(a) ++ Map.keys(b) |> Enum.uniq()
    diffs = Enum.map(keys, fn k -> (Map.get(a, k, 0.0) - Map.get(b, k, 0.0)) ** 2 end)
    :math.sqrt(Enum.sum(diffs) / max(length(diffs), 1))
  end

  defp compute_lipschitz(history) do
    distances = :queue.to_list(history)
    pairs = Enum.zip(tl(distances), distances)
    if length(pairs) < 2 do
      1.0
    else
      ratios = Enum.map(pairs, fn {next, prev} -> if prev > 0, do: next / prev, else: 1.0 end)
      Enum.max(ratios)
    end
  end
end