defmodule Tiannara.REA.Causal.Channel do
  @moduledoc """
  A typed, directed edge between two populations in the causal graph.
  
  A channel:
    * Extracts a specific signal_type from source organisms
    * Applies a transfer_fn (aggregation + transformation)
    * Delivers the result as environmental pressure to target organisms
    * Propagates with configurable delay and decay
  """
  
  alias Tiannara.REA.Causal.Signal
  
  @type endpoint :: %{population: atom(), signal: Signal.signal_type()}
  
  @type transfer_fn :: ([Signal.t()] -> float())
  
  @type t :: %__MODULE__{
    id: binary(),
    name: atom(),
    source: endpoint(),
    target: endpoint(),
    transfer_fn: transfer_fn(),
    delay: non_neg_integer(),
    decay: float(),
    weight: float(),
    enabled: boolean(),
    metadata: map()
  }
  
  defstruct [
    :id,
    :name,
    :source,
    :target,
    :transfer_fn,
    delay: 0,
    decay: 1.0,
    weight: 1.0,
    enabled: true,
    metadata: %{}
  ]
  
  @doc "Create a channel. `transfer_fn` defaults to mean aggregation."
  @spec new(keyword()) :: t()
  def new(opts) do
    id = :crypto.strong_rand_bytes(8) |> Base.encode16(case: :lower)
    %__MODULE__{
      id: id,
      name: Keyword.fetch!(opts, :name),
      source: Keyword.fetch!(opts, :source),
      target: Keyword.fetch!(opts, :target),
      transfer_fn: Keyword.get(opts, :transfer_fn, &mean/1),
      delay: Keyword.get(opts, :delay, 0),
      decay: Keyword.get(opts, :decay, 1.0),
      weight: Keyword.get(opts, :weight, 1.0),
      enabled: Keyword.get(opts, :enabled, true),
      metadata: Keyword.get(opts, :metadata, %{})
    }
  end
  
  # --- Common transfer functions ---
  
  @doc "Mean of signal values."
  def mean(signals) when is_list(signals) do
    case signals do
      [] -> 0.0
      ss -> Enum.map(ss, & &1.value) |> Enum.sum() |> Kernel./(length(ss))
    end
  end
  
  @doc "Max of signal values (strongest signal wins)."
  def max_signal(signals) when is_list(signals) do
    case signals do
      [] -> 0.0
      ss -> Enum.map(ss, & &1.value) |> Enum.max()
    end
  end
  
  @doc "Min of signal values (weakest-link constraint)."
  def min_signal(signals) when is_list(signals) do
    case signals do
      [] -> 0.0
      ss -> Enum.map(ss, & &1.value) |> Enum.min()
    end
  end
  
  @doc "Variance — measures disagreement in source population."
  def variance(signals) when is_list(signals) do
    case signals do
      [] -> 0.0
      ss ->
        values = Enum.map(ss, & &1.value)
        m = Enum.sum(values) / length(values)
        values |> Enum.map(&((&1 - m) * (&1 - m))) |> Enum.sum() |> Kernel./(length(values))
    end
  end
  
  @doc "Apply a custom transform after aggregation."
  @spec transform(t(), ([Signal.t()] -> float()), (float() -> float())) :: t()
  def transform(%__MODULE__{} = ch, aggregator, post_fn) do
    %{ch | transfer_fn: fn signals -> signals |> aggregator.() |> post_fn.() end}
  end
end
