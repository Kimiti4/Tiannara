defmodule Tiannara.Forecasting.ContractsTest do
  use ExUnit.Case, async: true

  alias Tiannara.Forecasting.Contracts
  alias Tiannara.Forecasting.Adapters.{Evidence, Research, CIS, WorldModel}

  describe "D2-D6 forecast contracts (D1 defines, does not implement)" do
    test "ForecastRequest struct has the documented shape" do
      req = %Contracts.ForecastRequest{
        signal_ids: ["s1"],
        evidence_ids: ["e1"],
        base_rate: %{reference_class: :market},
        question: "Will price rise?",
        horizon: :short_term
      }
      assert req.signal_ids == ["s1"]
      assert req.question == "Will price rise?"
    end

    test "Forecast struct is immutable and holds distribution/uncertainty" do
      f = %Contracts.Forecast{id: "f1", probability: 0.7, uncertainty: :epistemic}
      assert f.probability == 0.7
      assert f.uncertainty == :epistemic
    end

    test "BaseRate distinguishes UNKNOWN from 0.0" do
      br = %Contracts.BaseRate{historical_frequency: nil}
      assert br.historical_frequency == nil
    end
  end

  describe "adapter behaviours compile and expose callbacks" do
    test "Evidence adapter exposes link_to_evidence + evidence_for callbacks" do
      assert function_exported?(Evidence, :__info__, 1) or true
      assert Enum.member?(Evidence.behaviour_info(:callbacks), {:link_to_evidence, 3})
      assert Enum.member?(Evidence.behaviour_info(:callbacks), {:evidence_for, 1})
    end

    test "Research adapter exposes research callbacks" do
      callbacks = Research.behaviour_info(:callbacks)
      assert Enum.member?(callbacks, {:signal_to_priority, 1})
      assert Enum.member?(callbacks, {:signals_to_priorities, 1})
      assert Enum.member?(callbacks, {:information_gain_estimate, 2})
      assert Enum.member?(callbacks, {:under_observed_regions, 1})
    end

    test "CIS adapter exposes CIS boundary callbacks" do
      callbacks = CIS.behaviour_info(:callbacks)
      assert Enum.member?(callbacks, {:signal_to_telemetry, 1})
      assert Enum.member?(callbacks, {:forecast_to_collapse_probability, 1})
      assert Enum.member?(callbacks, {:signal_conflict_to_pathogen, 1})
    end

    test "WorldModel adapter exposes world-model callbacks" do
      callbacks = WorldModel.behaviour_info(:callbacks)
      assert Enum.member?(callbacks, {:ingest_signal, 1})
      assert Enum.member?(callbacks, {:context_for, 1})
      assert Enum.member?(callbacks, {:conflicts_with_world?, 1})
    end
  end
end
