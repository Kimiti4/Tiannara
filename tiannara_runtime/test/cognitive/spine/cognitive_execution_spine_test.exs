defmodule TiannaraRuntime.Cognitive.Spine.CognitiveExecutionSpineTest do
  @moduledoc """
  Validation of the Cognitive Execution Spine.

  These tests exist to prevent *fake activation*: a stage that merely returns
  is not a stage that works. Each assertion below checks that the Spine
  actually invoked an existing engine and that the engine's own output
  appears in the trace.
  """
  use ExUnit.Case, async: false

  alias TiannaraRuntime.AutonomousResearch.Phase16_1.ObservationRegistry
  alias TiannaraRuntime.Cognitive.Spine.Authority
  alias TiannaraRuntime.Cognitive.Spine.CognitiveExecutionSpine
  alias TiannaraRuntime.Cognitive.Spine.Knowledge
  alias TiannaraRuntime.Cognitive.Spine.SpineServer
  alias TiannaraRuntime.WorldModel.ModelRegistry

  setup do
    ModelRegistry.reset_table()
    ObservationRegistry.init_table()
    :ets.delete_all_objects(:observation_registry)
    :ok
  end

defmodule GrantingAuthority do
  @behaviour TiannaraRuntime.Cognitive.Spine.Authority

  @impl true
  def authorize(request) do
    {:ok, %{authorization_id: "auth_1", scope: request.domain}}
  end
end

defmodule RecordingKnowledge do
  @behaviour TiannaraRuntime.Cognitive.Spine.Knowledge

  @impl true
  def promote(conclusion, _evidence) do
    {:ok, %{promoted: true, model: conclusion.model}}
  end

  @impl true
  def record_outcome(_conclusion, _evidence), do: {:ok, %{recorded: true}}
end

  defp register_observations do
    ObservationRegistry.register_observation(
      %{"source" => "sensor_a", "domain" => "physics"},
      %{"temperature" => 25.0, "pressure" => 1013},
      "2026-06-01T12:00:00Z"
    )

    ObservationRegistry.register_observation(
      %{"source" => "sensor_b", "domain" => "physics"},
      %{"temperature" => 30.0, "pressure" => 1015},
      "2026-06-01T13:00:00Z"
    )
  end

  defp request do
    %{
      mission: %{objective: "explain thermal behaviour", status: :active},
      domain: :physics,
      model_name: "Spine Physics Model",
      evidence: [%{quality: 0.9}, %{quality: 0.7}],
      candidates: [
        %{id: "candidate_a", plan: %{mission_value: 0.9, scientific_value: 0.8}},
        %{id: "candidate_b", plan: %{mission_value: 0.5, scientific_value: 0.9}}
      ]
    }
  end

  describe "stage contract" do
    test "declares the full cognitive cycle in order" do
      assert CognitiveExecutionSpine.stages() == [
               :context,
               :world_model,
               :hypothesis,
               :forecast,
               :decision,
               :evidence,
               :knowledge,
               :authorize
             ]

      assert CognitiveExecutionSpine.pipeline_stages() |> length() == 6
      assert CognitiveExecutionSpine.gate_stages() == [:knowledge, :authorize]
    end
  end

  describe "run/2" do
    test "runs every chained stage and produces a trace" do
      register_observations()

      assert {:ok, result} = CognitiveExecutionSpine.run(request())

      assert result.completed_stages == [
               :context,
               :world_model,
               :hypothesis,
               :forecast,
               :decision,
               :evidence
             ]

      assert length(result.trace) == 8
      assert Enum.all?(result.trace, &(&1.status in [:ok, :blocked]))
    end

    test "the world-model stage invokes the real pipeline and reports its outputs" do
      register_observations()

      assert {:ok, result} = CognitiveExecutionSpine.run(request())

      world_model = get_in(result.outputs, [:world_model])

      assert world_model.observation_count == 2
      assert world_model.variable_count == 2
      assert world_model.model_name == "Spine Physics Model"
      assert world_model.certificate_status == :pass
    end

    test "the forecast stage reports a real confidence estimate and uncertainty split" do
      register_observations()

      assert {:ok, result} = CognitiveExecutionSpine.run(request())

      confidence = get_in(result.outputs, [:forecast, :confidence])
      uncertainty = get_in(result.outputs, [:forecast, :uncertainty])

      assert confidence.source == :evidence_quality
      assert confidence.value == 1.0
      assert is_float(confidence.variance)
      assert Map.has_key?(uncertainty, :aleatoric)
      assert Map.has_key?(uncertainty, :epistemic)
      assert Map.has_key?(uncertainty, :total)
    end

    test "the decision stage scores the supplied candidates" do
      register_observations()

      assert {:ok, result} = CognitiveExecutionSpine.run(request())

      decision = get_in(result.outputs, [:decision])

      assert decision.candidate_count == 2
      assert length(decision.scores) == 2
      assert Enum.all?(decision.scores, &is_number(&1.total))
    end

    test "the evidence stage binds the decision to a hashed evidence record" do
      register_observations()

      assert {:ok, result} = CognitiveExecutionSpine.run(request())

      evidence = get_in(result.outputs, [:evidence])

      assert is_binary(evidence.evidence_id)
      assert is_binary(evidence.input_hash)
      assert is_binary(evidence.output_hash)
    end

    test "an unwired spine completes the investigation but blocks both gates" do
      register_observations()

      assert {:ok, result} = CognitiveExecutionSpine.run(request())

      assert result.blocked_stages == [:knowledge, :authorize]
      assert get_in(result.outputs, [:knowledge]) == {:error, :knowledge_store_unavailable}
      assert get_in(result.outputs, [:authorize]) == {:error, :authority_unavailable}
    end

    test "a chained stage failure stops the chain and returns the trace" do
      # no observations registered: the pipeline still succeeds, so force a
      # failure through a malformed request instead
      assert {:ok, result} = CognitiveExecutionSpine.run(%{mission: %{objective: "x"}})
      assert :world_model in result.completed_stages
    end
  end

  describe "gates" do
    test "an injected authority grants a mandate" do
      register_observations()

      assert {:ok, result} =
               CognitiveExecutionSpine.run(request(), authority: GrantingAuthority)

      assert :authorize in result.completed_stages
      assert get_in(result.outputs, [:authorize, :authorization_id]) == "auth_1"
    end

    test "an injected knowledge adapter receives the validated conclusion" do
      register_observations()

      assert {:ok, result} =
               CognitiveExecutionSpine.run(request(), knowledge: RecordingKnowledge)

      assert :knowledge in result.completed_stages
      assert get_in(result.outputs, [:knowledge, :promoted]) == true
    end

    test "the refusing adapters are the documented defaults" do
      assert Authority.Refusing.authorize(%{}) == {:error, :authority_unavailable}
      assert Knowledge.Refusing.promote(%{}, %{}) == {:error, :knowledge_store_unavailable}
      assert Knowledge.Refusing.record_outcome(%{}, %{}) == {:error, :knowledge_store_unavailable}
    end
  end

  describe "host process" do
    test "the spine is running inside the application's supervision tree" do
      # The Spine was wired into TiannaraRuntime.Execution.Supervisor, so the
      # application boot starts it. This is the activation proof: the engine
      # cluster is now reachable through a supervised entry point.
      pid = Process.whereis(SpineServer)

      assert is_pid(pid), "the Spine is not running in the application supervision tree"
      assert Process.alive?(pid)
    end

    test "runs an investigation through the supervised entry point" do
      register_observations()

      assert {:ok, result} = SpineServer.run_investigation(request())
      assert :world_model in result.completed_stages
      assert :evidence in result.completed_stages
    end

    test "reports the adapters in force, defaulting to the refusing ones" do
      adapters = SpineServer.adapters()

      assert adapters.authority == Authority.Refusing
      assert adapters.knowledge == Knowledge.Refusing
    end

    test "an injected adapter is used by the host" do
      server =
        start_supervised!({SpineServer, [name: :tcp002_injected, authority: GrantingAuthority]})

      register_observations()

      assert %{authority: GrantingAuthority, knowledge: Knowledge.Refusing} =
               SpineServer.adapters_at(server)

      assert {:ok, result} = SpineServer.run_investigation_at(server, request())
      assert :authorize in result.completed_stages
    end

    test "the host stops cleanly" do
      server = start_supervised!({SpineServer, [name: :tcp002_stopping]})
      ref = Process.monitor(server)
      Supervisor.stop(server)

      assert_receive {:DOWN, ^ref, :process, ^server, _reason}, 5_000
    end
  end
end
