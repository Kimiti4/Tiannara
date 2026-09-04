defmodule Tiannara.REA.Epistemic.ReflexivityObservatory do
  @moduledoc """
  Observes MetaGenome lineages to classify their strategic behavior.
  
  Classification spectrum:
    :innovator              — proposals improve system integrity without
                              serving proposer's specific weakness
    :innovator_gamer_hybrid — proposals succeed AND disproportionately
                              benefit the proposer's existing capabilities
    :conservator            — low proposal rate, high parametric tuning
    :pure_gamer             — proposals primarily serve proposer's weakness,
                              with minimal system-wide benefit
  
  The Observatory is diagnostic, not punitive. It produces legibility
  so that governance decisions (like ReplacementRegistry promotion)
  can weigh second-order effects.
  """
  use GenServer
  
  @type lineage_profile :: %{
    lineage_id: binary(),
    classification: :innovator | :innovator_gamer_hybrid | :conservator | :pure_gamer,
    proposal_count: non_neg_integer(),
    proposal_success_count: non_neg_integer(),
    self_referential_rate: float(),
    system_integrity_contribution: float(),
    parametric_tuning_rate: float(),
    confidence: float()
  }
  
  @type event :: %{
    lineage_id: binary(),
    event_type: :proposal_made | :proposal_succeeded | :proposal_failed | :parametric_tune,
    epoch: non_neg_integer(),
    details: map()
  }
  
  def start_link(opts \\ []), do: GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  
  @spec record_event(event()) :: :ok
  def record_event(event), do: GenServer.cast(__MODULE__, {:event, event})
  
  @spec classify(binary()) :: lineage_profile() | nil
  def classify(lineage_id), do: GenServer.call(__MODULE__, {:classify, lineage_id})
  
  @spec all_classifications() :: [lineage_profile()]
  def all_classifications, do: GenServer.call(__MODULE__, :all)
  
  @spec summary() :: map()
  def summary, do: GenServer.call(__MODULE__, :summary)
  
  # --- Server ---
  
  @impl true
  def init(_), do: {:ok, %{events: %{}}}  # lineage_id -> [event]
  
  @impl true
  def handle_cast({:event, event}, state) do
    events = Map.update(state.events, event.lineage_id, [event], &[event | &1])
    {:noreply, %{state | events: events}}
  end
  
  @impl true
  def handle_call({:classify, lineage_id}, _from, state) do
    events = Map.get(state.events, lineage_id, [])
    profile = build_profile(lineage_id, events)
    {:reply, profile, state}
  end
  
  @impl true
  def handle_call(:all, _from, state) do
    profiles = Enum.map(state.events, fn {lid, evts} -> build_profile(lid, evts) end)
    {:reply, profiles, state}
  end
  
  @impl true
  def handle_call(:summary, _from, state) do
    profiles = Enum.map(state.events, fn {lid, evts} -> build_profile(lid, evts) end)
    summary = profiles
    |> Enum.group_by(& &1.classification)
    |> Enum.map(fn {cls, ps} -> {cls, length(ps)} end)
    |> Map.new()
    {:reply, summary, state}
  end

  @impl true
  def handle_call({:reset}, _from, _state), do: {:reply, :ok, %{events: %{}}}
  
  # --- Classification Logic ---
  
  defp build_profile(lineage_id, events) do
    proposals = Enum.filter(events, &(&1.event_type == :proposal_made))
    successes = Enum.filter(events, &(&1.event_type == :proposal_succeeded))
    _failures = Enum.filter(events, &(&1.event_type == :proposal_failed))
    tunes = Enum.filter(events, &(&1.event_type == :parametric_tune))
    
    proposal_count = length(proposals)
    success_count = length(successes)
    success_rate = if proposal_count > 0, do: success_count / proposal_count, else: 0.0
    
    # Self-referential rate: % of proposals where the proposer's weakness
    # matches the removed dependency
    self_ref_count = Enum.count(proposals, fn e ->
      Map.get(e.details, :self_referential, false)
    end)
    self_ref_rate = if proposal_count > 0, do: self_ref_count / proposal_count, else: 0.0
    
    # System integrity contribution: average epistemic_integrity of successful proposals
    integrity_contrib = case successes do
      [] -> 0.0
      ss ->
        ss
        |> Enum.map(fn e -> Map.get(e.details, :epistemic_integrity, 0.5) end)
        |> Enum.sum()
        |> Kernel./(length(ss))
    end
    
    # Parametric tuning rate: tunes per epoch
    epoch_span = epoch_span(events)
    tuning_rate = if epoch_span > 0, do: length(tunes) / epoch_span, else: 0.0
    
    classification = classify_lineage(%{
      proposal_count: proposal_count,
      success_rate: success_rate,
      self_ref_rate: self_ref_rate,
      integrity_contrib: integrity_contrib,
      tuning_rate: tuning_rate
    })
    
    confidence = min(proposal_count / 10.0, 1.0)
    
    %{
      lineage_id: lineage_id,
      classification: classification,
      proposal_count: proposal_count,
      proposal_success_count: success_count,
      self_referential_rate: self_ref_rate,
      system_integrity_contribution: integrity_contrib,
      parametric_tuning_rate: tuning_rate,
      confidence: confidence
    }
  end
  
  defp classify_lineage(%{
    proposal_count: pc,
    success_rate: sr,
    self_ref_rate: srr,
    integrity_contrib: ic,
    tuning_rate: tr
  }) do
    cond do
      # Pure gamer: high self-reference, high success, low integrity contribution
      pc >= 3 and srr > 0.7 and sr > 0.5 and ic < 0.5 ->
        :pure_gamer
      
      # Innovator-gamer hybrid: successful proposals, but many are self-referential
      pc >= 3 and srr > 0.4 and sr > 0.5 and ic >= 0.5 ->
        :innovator_gamer_hybrid
      
      # Conservator: low proposal rate, high tuning rate
      pc <= 3 and tr > 0.05 ->
        :conservator
      
      # Innovator: successful proposals with low self-reference, high integrity
      pc >= 3 and srr < 0.3 and sr > 0.5 and ic >= 0.6 ->
        :innovator
      
      # Fallback: insufficient data or mixed signals
      true ->
        cond do
          sr > 0.5 and ic >= 0.5 -> :innovator
          tr > 0.05 -> :conservator
          true -> :innovator_gamer_hybrid
        end
    end
  end
  
  defp epoch_span([]), do: 0
  defp epoch_span(events) do
    epochs = Enum.map(events, & &1.epoch)
    Enum.max(epochs) - Enum.min(epochs)
  end
end
