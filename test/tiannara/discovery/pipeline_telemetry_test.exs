defmodule Tiannara.Discovery.PipelineTelemetryTest do
  use ExUnit.Case, async: false

  @valid_statuses [:growing, :flat, :regressed, :present, :uninstrumented, :error]

  setup do
    Application.ensure_all_started(:tiannara)
    :ok
  end

  test "snapshot covers every pipeline stage with a valid status" do
    snap = Tiannara.Discovery.PipelineTelemetry.snapshot()

    assert map_size(snap.stages) == 9
    assert length(Tiannara.Discovery.PipelineTelemetry.stages()) == 9

    Enum.each(Tiannara.Discovery.PipelineTelemetry.stages(), fn stage ->
      assert %{status: status} = snap.stages[stage]
      assert status in @valid_statuses
    end)

    assert snap.sample_count >= 1
    assert snap.sampled_at != nil
    assert snap.started_at != nil
    assert is_list(snap.uninstrumented)
    assert snap.first_stall == nil or is_map(snap.first_stall)
  end

  test "every stage resolves a real counter when its source process is up" do
    snap = Tiannara.Discovery.PipelineTelemetry.snapshot()

    all_up =
      Process.whereis(Tiannara.Discovery.DiscoveryScheduler) != nil and
        Process.whereis(Tiannara.Discovery.DiscoveryEngine) != nil and
        Process.whereis(Tiannara.World.UnifiedWorldModel) != nil and
        Process.whereis(Tiannara.World.UnifiedRealityGraph) != nil

    if all_up do
      assert snap.uninstrumented == [], "grey stages: #{inspect(snap.uninstrumented)}"
    end

    for stage <- Tiannara.Discovery.PipelineTelemetry.stages(),
        stage not in snap.uninstrumented do
      assert is_integer(snap.stages[stage].value) or stage == :knowledge_integration
    end

    if all_up do
      assert is_integer(snap.stages.knowledge_integration.value)
      assert snap.stages.knowledge_integration.value <= snap.stages.observation.value
    end

    assert snap.seeded_inputs == nil or is_integer(snap.seeded_inputs)
  end

  test "world model growth lights observation and knowledge_integration green" do
    before = Tiannara.Discovery.PipelineTelemetry.snapshot()

    id = "pipeline_test_growth_#{System.unique_integer([:positive])}"

    assert {:ok, _} =
             Tiannara.World.UnifiedWorldModel.create_entity(%{
               id: id,
               type: :fact,
               subtype: :observation,
               domain: :sensor_fusion,
               attributes: %{property: "pipeline_test", value: "growth"},
               confidence: 0.5,
               provenance: %{origin: :pipeline_test}
             })

    after_snap = Tiannara.Discovery.PipelineTelemetry.snapshot()

    assert after_snap.stages.observation.value > before.stages.observation.value
    assert after_snap.stages.observation.status == :growing

    assert after_snap.stages.knowledge_integration.value >
             before.stages.knowledge_integration.value

    assert after_snap.stages.knowledge_integration.status == :growing
  end

  test "history accumulates and caps at 500 samples" do
    Enum.each(1..510, fn _ -> Tiannara.Discovery.PipelineTelemetry.snapshot() end)

    history = Tiannara.Discovery.PipelineTelemetry.history()
    assert length(history) == 500
    assert List.last(history).sampled_at != nil
    assert List.last(history).sample_count > 500
  end

  test "first_stall is nil when every stage has a real counter" do
    all_up =
      Process.whereis(Tiannara.Discovery.DiscoveryScheduler) != nil and
        Process.whereis(Tiannara.Discovery.DiscoveryEngine) != nil and
        Process.whereis(Tiannara.World.UnifiedWorldModel) != nil and
        Process.whereis(Tiannara.World.UnifiedRealityGraph) != nil

    stall = Tiannara.Discovery.PipelineTelemetry.first_stall()

    if all_up do
      assert stall == nil
    else
      assert stall == nil or stall.status == :uninstrumented
    end
  end
end
