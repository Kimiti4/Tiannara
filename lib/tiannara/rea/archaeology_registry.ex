defmodule Tiannara.REA.ArchaeologyRegistry do
  @moduledoc """
  Single registry for all evolutionary ruins, regardless of type.
  
  Specialized queries (only laws, only civilizations) are filters
  over this one registry, not separate registries.
  """
  use GenServer
  
  alias Tiannara.REA.EvolutionaryRuin
  
  @max_ruins 10000
  
  def start_link(opts \\ []), do: GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  
  @spec inter(EvolutionaryRuin.t()) :: :ok
  def inter(%EvolutionaryRuin{} = ruin), do: GenServer.call(__MODULE__, {:inter, ruin})
  
  @spec all() :: [EvolutionaryRuin.t()]
  def all, do: GenServer.call(__MODULE__, :all)
  
  @spec by_type(atom()) :: [EvolutionaryRuin.t()]
  def by_type(type), do: GenServer.call(__MODULE__, {:by_type, type})
  
  @spec collapse_report(non_neg_integer()) :: map()
  def collapse_report(since_epoch), do: GenServer.call(__MODULE__, {:collapse_report, since_epoch})
  
  @spec reset() :: :ok
  def reset, do: GenServer.call(__MODULE__, :reset)
  
  @impl true
  def init(_), do: {:ok, %{ruins: []}}
  
  @impl true
  def handle_call(:reset, _, state), do: {:reply, :ok, %{state | ruins: []}}
  
  @impl true
  def handle_call({:inter, ruin}, _, %{ruins: ruins} = state) do
    # Cap the size of ruins to prevent geometric memory leak over long horizons
    new_ruins = Enum.take([ruin | ruins], @max_ruins)
    {:reply, :ok, %{state | ruins: new_ruins}}
  end
  
  @impl true
  def handle_call(:all, _, %{ruins: ruins} = state),
    do: {:reply, ruins, state}
  
  @impl true
  def handle_call({:by_type, type}, _, %{ruins: ruins} = state),
    do: {:reply, Enum.filter(ruins, &(&1.organism_type == type)), state}
  
  @impl true
  def handle_call({:collapse_report, since}, _, %{ruins: ruins} = state) do
    recent = Enum.filter(ruins, &(&1.epoch >= since))
    report = %{
      total: length(recent),
      by_type: recent |> Enum.group_by(& &1.organism_type) |> Map.new(fn {t, rs} -> {t, length(rs)} end),
      by_reason: recent |> Enum.group_by(& &1.collapse_signature.reason) |> Map.new(fn {r, rs} -> {r, length(rs)} end),
      avg_lifespan_generations: avg_lifespan(recent)
    }
    {:reply, report, state}
  end
  
  defp avg_lifespan([]), do: 0.0
  defp avg_lifespan(rs) do
    Enum.map(rs, & &1.collapse_signature.generation_lifespan) |> Enum.sum() |> Kernel./(length(rs))
  end
end
