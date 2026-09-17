defmodule TiannaraOS.RepositoryTwinWorldTest do
  use ExUnit.Case, async: false

  alias TiannaraOS.State
  alias TiannaraOS.World
  alias TiannaraOS.RepositoryTwin
  alias TiannaraOS.EvidenceNode
  alias TiannaraOS.EvidenceEngine
  alias TiannaraOS.CivilizationKernel
  alias TiannaraOS.Discovery

  setup do
    case Process.whereis(CivilizationKernel) do
      nil -> {:ok, _pid} = CivilizationKernel.start_link()
      _pid -> :ok
    end

    # Reset state to default
    CivilizationKernel.update_state(fn _ ->
      %State{
        worlds: %{},
        theories: %{},
        institutions: %{},
        tools: %{},
        evidence_graph: %{},
        discoveries: %{},
        security: %{policy_mode: :strict},
        governance: %{
          active_mode: :balanced,
          constitutional_events: [],
          overrides: [],
          audit_log: []
        }
      }
    end)

    {:ok, %{}}
  end

  test "PR and Merge Validation: branch isolation, PR merges, and disk persistence" do
    # 1. Spawn twin with vulnerable plug package
    {:ok, twin} = RepositoryTwin.create_twin(:test_repo, "vulnerable_proj", %{
      dependencies: %{"plug" => "1.13.0"}
    })

    # 2. Add branch and switch
    twin =
      twin
      |> RepositoryTwin.create_branch("fix-deps")
      |> RepositoryTwin.checkout_branch("fix-deps")

    # 3. Commit fixed mix.exs content
    fixed_mix_content = """
    defmodule Simulated.MixProject do
      use Mix.Project
      def project do
        [deps: [
          {:plug, "1.14.0"}
        ]]
      end
    end
    """
    
    twin = RepositoryTwin.commit_changes(twin, "auditor", "upgrade plug to 1.14.0", %{
      "mix.exs" => fixed_mix_content
    })

    # Assert branch has the update
    content_fix_branch = File.read!(Path.join(twin.path, "mix.exs"))
    assert String.contains?(content_fix_branch, "{:plug, \"1.14.0\"}")

    # 4. Open PR and Merge back to main
    twin =
      twin
      |> RepositoryTwin.open_pull_request("Fix plug vulnerability", "fix-deps", "main")
      |> RepositoryTwin.checkout_branch("main")
      |> RepositoryTwin.merge_pull_request(1, "maintainer")

    # Assert main now contains the upgrade
    content_main_branch = File.read!(Path.join(twin.path, "mix.exs"))
    assert String.contains?(content_main_branch, "{:plug, \"1.14.0\"}")

    # Verify PR status
    merged_pr = Enum.find(twin.pull_requests, &(&1.id == 1))
    assert merged_pr.status == :merged

    # Verify event logs
    events = Enum.map(twin.world_events, & &1.type)
    assert :branch_created in events
    assert :pr_opened in events
    assert :pr_merged in events

    # Cleanup disk
    RepositoryTwin.cleanup_twin(twin)
  end

  test "CI runs generate EvidenceNodes and revise JTMS belief confidence" do
    # 1. Register Theory and Claim
    theory = %EvidenceNode{id: :ci_theory, type: :theory, name: "CI Security Theory", value: 1.0, validity: :valid}
    claim = %EvidenceNode{id: :ci_claim, type: :claim, name: "CI Passes claim", value: 1.0, validity: :valid}

    # Set up initial JTMS state
    {:ok, _state} = CivilizationKernel.update_state(fn current_state ->
      initial_graph =
        current_state.evidence_graph
        |> Map.put(:ci_theory, theory)
        |> Map.put(:ci_claim, claim)

      %{current_state | evidence_graph: initial_graph}
    end)

    # Link Theory -> Claim
    {:ok, _state} = CivilizationKernel.update_state(fn current_state ->
      EvidenceEngine.add_relation(current_state, :ci_theory, :predicts, :ci_claim)
    end)

    # 2. Spawn twin with vulnerable dependency
    {:ok, twin} = RepositoryTwin.create_twin(:ci_repo, "ci_proj", %{
      dependencies: %{"plug" => "1.13.0"}
    })

    # Register twin in a World conforming wrapper
    world = %World{
      id: :repo_world_instance,
      name: "Stateful Repository World",
      template_id: :cybersecurity,
      twin: twin
    }

    {:ok, state} = CivilizationKernel.update_state(fn current_state ->
      %{current_state | worlds: Map.put(current_state.worlds, :repo_world_instance, world)}
    end)

    # 3. Run CI - should fail since plug is vulnerable (1.13.0)
    {:ok, twin_after_run, evidence_node} = RepositoryTwin.run_ci_pipeline(twin, :repo_world_instance)

    assert evidence_node.value == 0.0 # CI Failed
    assert evidence_node.metadata.source == :ci_pipeline
    assert evidence_node.metadata.ci_outcome == :failure

    # 4. Feed CI failure evidence back to JTMS Claim
    state = EvidenceEngine.add_node(state, evidence_node.id, evidence_node)
    # Mocking link where the claim is supported/invalidated by this CI outcome
    state = EvidenceEngine.add_relation(state, evidence_node.id, :supports, :ci_claim)
    state = EvidenceEngine.refute_evidence(state, evidence_node.id)

    # Verify claim degraded by 0.7
    claim_node = Map.get(state.evidence_graph, :ci_claim)
    assert_in_delta claim_node.value, 0.7, 0.001

    # Verify theory degraded by 0.7
    theory_node = Map.get(state.evidence_graph, :ci_theory)
    assert_in_delta theory_node.value, 0.7, 0.001

    # 5. Fix the code twin on main, run CI again and assert recovery
    fixed_mix_content = """
    defmodule Simulated.MixProject do
      use Mix.Project
      def project do
        [deps: [
          {:plug, "1.14.0"}
        ]]
      end
    end
    """
    twin_after_run = RepositoryTwin.commit_changes(twin_after_run, "auditor", "upgrade plug", %{
      "mix.exs" => fixed_mix_content
    })

    {:ok, twin_fixed, success_evidence} = RepositoryTwin.run_ci_pipeline(twin_after_run, :repo_world_instance)
    assert success_evidence.value == 1.0 # CI Successful!

    # Verify CI success rate metric
    assert twin_fixed.metrics.ci_success_rate == 0.5 # 1 fail, 1 success

    # Cleanup twin disk
    RepositoryTwin.cleanup_twin(twin_fixed)
  end

  test "Discovery Candidate Registry: validates candidate records, validation levels, and metric scores" do
    discovery = %Discovery{
      id: :vuln_leak_discovery,
      source_world: :repo_world_instance,
      evidence_ids: [:ev_ci_1],
      theory_ids: [:ci_theory],
      validation_level: :l1,
      status: :candidate,
      evidence_score: 0.8,
      replication_score: 0.0,
      security_score: 0.9,
      novelty_score: 0.6,
      transferability_score: 0.7
    }

    # Verify scores and validation defaults
    assert discovery.validation_level == :l1
    assert discovery.status == :candidate
    assert discovery.evidence_score == 0.8
    assert discovery.security_score == 0.9
    assert discovery.novelty_score == 0.6
    assert discovery.transferability_score == 0.7

    # Add to OS state vector
    {:ok, state} = CivilizationKernel.update_state(fn current_state ->
      %{current_state | discoveries: Map.put(current_state.discoveries, :vuln_leak_discovery, discovery)}
    end)

    # Verify registry retrieves candidate correctly
    retrieved = Map.get(state.discoveries, :vuln_leak_discovery)
    assert retrieved.id == :vuln_leak_discovery
    assert retrieved.status == :candidate
  end
end
