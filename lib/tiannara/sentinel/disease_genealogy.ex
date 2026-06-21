defmodule Tiannara.Sentinel.DiseaseGenealogy do
  @moduledoc """
  Sentinel D.2: Tracks the evolutionary history of Epistemic Diseases.
  Answers questions like: Which diseases survive longest? Which resist cures?
  """
  use GenServer
  require Logger

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc "Record the emergence or mutation of a disease."
  def record_disease(disease) do
    GenServer.cast(__MODULE__, {:record_disease, disease})
  end

  @doc "Record a transmission event."
  def record_transmission(disease_id, from_civ, to_civ) do
    GenServer.cast(__MODULE__, {:record_transmission, disease_id, from_civ, to_civ})
  end

  @doc "Record a cure event by a specific civilization."
  def record_cure(disease_id, civ_id, immune_adaptations_used) do
    GenServer.cast(__MODULE__, {:record_cure, disease_id, civ_id, immune_adaptations_used})
  end

  @impl true
  def init(_opts) do
    Logger.info("Starting Sentinel Disease Genealogy")
    {:ok, %{
      diseases: %{},     # id -> disease snapshot
      transmissions: [], # {id, from, to, timestamp}
      cures: []          # {id, civ, immune_adaptations, timestamp}
    }}
  end

  @impl true
  def handle_cast({:record_disease, disease}, state) do
    new_diseases = Map.put(state.diseases, disease.id, disease)
    {:noreply, %{state | diseases: new_diseases}}
  end

  @impl true
  def handle_cast({:record_transmission, disease_id, from_civ, to_civ}, state) do
    event = {disease_id, from_civ, to_civ, System.system_time(:millisecond)}
    {:noreply, %{state | transmissions: [event | state.transmissions]}}
  end

  @impl true
  def handle_cast({:record_cure, disease_id, civ_id, immune_adaptations}, state) do
    event = {disease_id, civ_id, immune_adaptations, System.system_time(:millisecond)}
    Logger.info("🧬 [Sentinel] Disease #{disease_id} cured by #{civ_id} using #{inspect(immune_adaptations)}")
    {:noreply, %{state | cures: [event | state.cures]}}
  end
end
