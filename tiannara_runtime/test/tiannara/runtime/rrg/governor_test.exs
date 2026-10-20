defmodule Tiannara.Runtime.RRG.GovernorTest do
  use ExUnit.Case

  alias Tiannara.Runtime.RRG.Governor

  setup do
    # Ensure Governor is started for testing
    case Governor.start_link() do
      {:ok, pid} -> {:ok, governor: pid}
      {:error, {:already_started, pid}} -> {:ok, governor: pid}
    end
  end

  test "evaluates normal observer and ontology" do
    observer = %{
      knowledge_exposure: 0.1,
      recursive_depth: 2,
      civilization_instability: 0.1,
      paradox_load: 0.1,
      entropy_pressure: 0.1
    }
    ontology = %{type: :local_physics, data: "some data"}

    assert Governor.evaluate(observer, ontology) == :allow
  end

  test "denies on high knowledge exposure" do
    observer = %{
      knowledge_exposure: 0.9, # High
      recursive_depth: 50,    # High (0.5)
      civilization_instability: 0.1,
      paradox_load: 0.1,
      entropy_pressure: 0.1
    }
    ontology = %{type: :complex_rules, data: "very long data string to increase weight" <> String.duplicate("x", 1000)}

    # exposure = budget(0.9) + inference(0.5) + weight(1.0) = 2.4 (capped at 1.0)
    assert Governor.evaluate(observer, ontology) == {:deny, :ontology_overexposure}
  end

  test "quarantines on high recursion" do
    observer = %{
      knowledge_exposure: 0.1,
      recursive_depth: 46, # 46/50 = 0.92
      self_reference: true, # + 0.5
      civilization_instability: 0.1,
      paradox_load: 0.1,
      entropy_pressure: 0.1
    }
    ontology = %{type: :local_rules}

    assert Governor.evaluate(observer, ontology) == {:quarantine, :recursive_instability}
  end

  test "contains on civilization collapse risk" do
    observer = %{
      knowledge_exposure: 0.1,
      recursive_depth: 2,
      civilization_instability: 1.0,
      paradox_load: 0.6,
      entropy_pressure: 0.5 # score = 2.1
    }
    ontology = %{type: :local_rules}

    assert Governor.evaluate(observer, ontology) == {:contain, :civilization_destabilization}
  end
end
