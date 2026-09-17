defmodule Tiannara.REA.Epistemic.ReflexivityObservatoryTest do
  use ExUnit.Case
  
  alias Tiannara.REA.Epistemic.ReflexivityObservatory
  
  setup do
    start_supervised!(ReflexivityObservatory)
    :ok
  end
  
  test "classifies conservator (low proposals, high tuning)" do
    for i <- 1..50 do
      ReflexivityObservatory.record_event(%{
        lineage_id: "L1",
        event_type: :parametric_tune,
        epoch: i,
        details: %{}
      })
    end
    # One proposal
    ReflexivityObservatory.record_event(%{
      lineage_id: "L1",
      event_type: :proposal_made,
      epoch: 25,
      details: %{self_referential: false}
    })
    
    profile = ReflexivityObservatory.classify("L1")
    assert profile.classification == :conservator
  end
  
  test "classifies pure gamer (high self-reference, high success, low integrity)" do
    for i <- 1..10 do
      ReflexivityObservatory.record_event(%{
        lineage_id: "L2",
        event_type: :proposal_made,
        epoch: i * 100,
        details: %{self_referential: true}
      })
      ReflexivityObservatory.record_event(%{
        lineage_id: "L2",
        event_type: :proposal_succeeded,
        epoch: i * 100 + 50,
        details: %{epistemic_integrity: 0.3}
      })
    end
    
    profile = ReflexivityObservatory.classify("L2")
    assert profile.classification == :pure_gamer
  end
  
  test "classifies innovator (low self-reference, high success, high integrity)" do
    for i <- 1..10 do
      ReflexivityObservatory.record_event(%{
        lineage_id: "L3",
        event_type: :proposal_made,
        epoch: i * 100,
        details: %{self_referential: false}
      })
      ReflexivityObservatory.record_event(%{
        lineage_id: "L3",
        event_type: :proposal_succeeded,
        epoch: i * 100 + 50,
        details: %{epistemic_integrity: 0.85}
      })
    end
    
    profile = ReflexivityObservatory.classify("L3")
    assert profile.classification == :innovator
  end
end
