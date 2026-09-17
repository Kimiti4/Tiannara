defmodule Tiannara.Phase16.REA.DomainRegistry do
  @moduledoc """
  Tracks cross-domain axiom schemas and computes baseline divergence metrics.
  """
  use GenServer

  @default_schemas %{
    physics: [:causal_linear, :conservation_energy, :symmetry_local],
    biology: [:adaptation_fitness, :heredity_dna, :homeostasis_feedback],
    economics: [:utility_maximization, :scarcity_allocation, :market_equilibrium]
  }

  def start_link(opts \\ []), do: GenServer.start_link(__MODULE__, opts, name: __MODULE__)

  @impl true
  def init(_opts), do: {:ok, %{schemas: @default_schemas, divergence_cache: %{}}}

  @spec schemas() :: map()
  def schemas, do: @default_schemas

  @spec compute_domain_overlap(domains :: [atom()]) :: float()
  def compute_domain_overlap(domains) do
    schemas = Enum.map(domains, fn d -> Map.get(@default_schemas, d, []) end)
    intersection = Enum.reduce(schemas, &MapSet.intersection/2) |> MapSet.to_list()
    union = Enum.reduce(schemas, &MapSet.union/2) |> MapSet.to_list()
    if length(union) == 0, do: 0.0, else: length(intersection) / length(union)
  end

  @spec get_baseline_divergence(domain_a :: atom(), domain_b :: atom()) :: float()
  def get_baseline_divergence(a, b) do
    case Map.fetch(@default_schemas, {a, b}) do
      {:ok, val} -> val
      :error -> 0.65 # Default moderate divergence
    end
  end
end