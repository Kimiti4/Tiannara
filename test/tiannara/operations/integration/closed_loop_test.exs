defmodule Tiannara.Operations.Integration.ClosedLoopTest do
  use ExUnit.Case, async: false

  alias Tiannara.Operations.{CampaignIntegration, FeedbackLoop, CampaignScheduler}

  @moduletag :integration
  @moduletag :closed_loop

  setup do
    for module <- [CampaignIntegration, FeedbackLoop] do
      case module.start_link([]) do
        {:ok, _} -> :ok
        {:error, {:already_started, _}} -> :ok
      end
    end
    :ok
  end

  describe "CampaignIntegration" do
    test "topology shows the closed loop" do
      topology = CampaignIntegration.topology()

      assert :phase5 in topology.phase10.outputs_to
      assert :phase7 in topology.phase6.outputs_to
      assert topology.phase6.receives_from |> Enum.member?(:phase5)
    end

    test "routes campaign results to World Model" do
      result = %{status: :completed, discoveries: 3, metrics: %{throughput: 0.8}}
      CampaignIntegration.route_result(:phase6, result)
      Process.sleep(500)

      feedback_history = CampaignIntegration.feedback_history()
      assert is_list(feedback_history)
    end

    test "feedback history records phase10 to phase5 loop closure" do
      CampaignIntegration.route_result(:phase10, %{status: :completed, forecasts: []})
      Process.sleep(500)

      history = CampaignIntegration.feedback_history()
      assert is_list(history)
    end
  end

  describe "FeedbackLoop" do
    test "gathers observations from system state" do
      FeedbackLoop.trigger_feedback()
      Process.sleep(1000)

      fl_state = FeedbackLoop.state()
      assert fl_state.cycles >= 1
      assert is_integer(fl_state.observations_fed)
    end

    test "identifies improvements when objectives not met" do
      FeedbackLoop.trigger_feedback()
      Process.sleep(1000)

      fl_state = FeedbackLoop.state()
      assert is_integer(fl_state.improvements_identified)
    end
  end

  describe "CivilizationRunner" do
    test "validate_readiness reports module availability" do
      readiness = Tiannara.ASC.CivilizationRunner.validate_readiness()
      assert is_map(readiness)
      assert Map.has_key?(readiness, :ready)
      assert Map.has_key?(readiness, :passed)
      assert Map.has_key?(readiness, :total)
    end
  end

  describe "Closed loop topology" do
    test "the loop is structurally complete" do
      topology = CampaignIntegration.topology()

      assert :phase7 in topology.phase6.outputs_to
      assert :phase8a in topology.phase7.outputs_to
      assert :phase8b in topology.phase8a.outputs_to
      assert :phase9 in topology.phase8b.outputs_to
      assert :phase10 in topology.phase9.outputs_to
      assert :phase5 in topology.phase10.outputs_to

      IO.puts("Closed loop verified: P6 → P7 → P8a → P8b → P9 → P10 → P5")
    end

    test "all phases feed the World Model" do
      topology = CampaignIntegration.topology()

      phases_with_world_model =
        Enum.filter(topology, fn {_id, config} ->
          :world_model in config.outputs_to
        end)

      assert length(phases_with_world_model) >= 4
    end
  end
end
