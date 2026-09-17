defmodule Tiannara.Runtime.RRG.Governor do
  @moduledoc """
  Phase 5F.7 / 5F.8 — Runtime Revelation Governor (RRG)

  Governs observers' access to raw ontology features, preventing compiler
  awareness cascades, escape risks, and recursive collapse of decoy ontologies.
  """

  use GenServer

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(state) do
    {:ok, state}
  end

  @doc """
  Evaluates whether to allow, quarantine, contain, or deny an observer query.
  """
  def evaluate(observer, _ontology) do
    knowledge_exposure = Map.get(observer, :knowledge_exposure, 0.0)
    recursive_depth = Map.get(observer, :recursive_depth, 0.0)
    self_reference = Map.get(observer, :self_reference, false)
    civilization_instability = Map.get(observer, :civilization_instability, 0.0)
    paradox_load = Map.get(observer, :paradox_load, 0.0)
    entropy_pressure = Map.get(observer, :entropy_pressure, 0.0)

    # 1. Check civilization destabilization
    civ_score = civilization_instability + paradox_load + entropy_pressure

    # 2. Check recursion
    rec_score = (recursive_depth / 50.0) + (if self_reference, do: 0.5, else: 0.0)

    cond do
      knowledge_exposure > 0.8 or recursive_depth >= 50 ->
        {:deny, :ontology_overexposure}

      civ_score > 2.0 ->
        {:contain, :civilization_destabilization}

      rec_score > 0.9 ->
        {:quarantine, :recursive_instability}

      true ->
        :allow
    end
  end
end
