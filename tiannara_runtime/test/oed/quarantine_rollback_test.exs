defmodule Tiannara.OED.QuarantineRollbackTest do
  use ExUnit.Case, async: false

  alias Tiannara.OED.Quarantine.{
    QuarantineRegistry,
    SuspendedTheories,
    ContradictionTracker,
    RehabilitationPipeline
  }

  alias Tiannara.OED.Rollback.RollbackController

  setup do
    start_supervised!(Tiannara.OED.Quarantine.QuarantineRegistry)
    start_supervised!(Tiannara.OED.Quarantine.SuspendedTheories)
    start_supervised!(Tiannara.OED.Quarantine.ContradictionTracker)
    start_supervised!(Tiannara.OED.Rollback.OntologySnapshots)
    start_supervised!(Tiannara.OED.Rollback.RollbackController)
    :ok
  end

  describe "Quarantine registry & suspended store" do
    test "suspends theory and retrieves registry indices" do
      theory = %{
        type: :compression_policy,
        body: {:apply, :default, []}
      }

      assert :ok == QuarantineRegistry.quarantine(theory, "un-stable")
      assert :ok == SuspendedTheories.store(theory.type, theory.body)

      assert {:ok, body} = SuspendedTheories.fetch(theory.type)
      assert body == theory.body

      records = QuarantineRegistry.list_quarantined()
      assert length(records) > 0
    end
  end

  describe "Contradiction tracker" do
    test "logs conflict records" do
      assert :ok == ContradictionTracker.record_conflict(:compression_policy, "infinite loop")
      conflicts = ContradictionTracker.get_conflicts()
      assert Map.has_key?(conflicts, :compression_policy)
    end
  end

  describe "Rehabilitation pipeline" do
    test "rehabilitates infinite regress using depth guards" do
      raw_rule = %{
        type: :compression_policy,
        body: {:apply, :adaptive, []}
      }

      assert {:ok, rehab} = RehabilitationPipeline.rehabilitate(raw_rule, "infinite regress")
      assert elem(rehab.body, 0) == :if
      # Deep guard injected
      assert elem(rehab.body, 1) == {:<=, :compilation_depth, 3}
    end
  end

  describe "RollbackController" do
    test "coordinates rollback sequence post-failure" do
      assert {:ok, snapshot} = RollbackController.trigger_rollback(:compression_policy, "psi depletion")
      assert snapshot.type == :compression_policy
    end
  end
end
