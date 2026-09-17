defmodule TiannaraOS.ToolEcologyTest do
  use ExUnit.Case, async: false

  alias TiannaraOS.State
  alias TiannaraOS.ToolGenome
  alias TiannaraOS.ToolGenomeEngine
  alias TiannaraOS.ToolRuntime
  alias TiannaraOS.RepositoryTwin
  alias TiannaraOS.EvidenceNode
  alias TiannaraOS.EvidenceEngine
  alias TiannaraOS.CivilizationKernel

  setup do
    # Ensure civilization kernel is running or clean state
    # If GenServer is already running, we clean its state, else start it.
    case Process.whereis(CivilizationKernel) do
      nil ->
        {:ok, _pid} = CivilizationKernel.start_link()
      _pid ->
        :ok
    end

    # Reset state to default
    CivilizationKernel.update_state(fn _ ->
      %State{
        worlds: %{},
        theories: %{},
        institutions: %{},
        tools: %{},
        evidence_graph: %{},
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

  test "Tool Genome Evolution: verifies mutation, parent lineage, and provenance tracking" do
    initial_spec = %{rules: [%{package: "plug", vulnerable_before: "1.14.0"}]}
    
    genome = ToolGenomeEngine.generate_genome(
      :dep_scanner,
      :find_insecure_dependency,
      :repository_analysis,
      :interpreter,
      initial_spec,
      provenance: ["initial_seed"]
    )

    assert genome.id == :dep_scanner
    assert genome.version == "0.1.0"
    assert genome.parent_genomes == []
    assert genome.provenance == ["initial_seed"]

    # Mutate genome spec
    mutated = ToolGenomeEngine.mutate_spec(
      genome,
      %{rules: [%{package: "plug", vulnerable_before: "1.15.0"}]},
      "expanded_audit_rules"
    )

    assert mutated.id != :dep_scanner
    assert mutated.version == "0.2.0"
    assert mutated.parent_genomes == [:dep_scanner]
    assert mutated.provenance == ["initial_seed", "expanded_audit_rules"]
    assert mutated.execution_spec.rules == [%{package: "plug", vulnerable_before: "1.15.0"}]
  end

  test "Tool Runtime Interpreter: scans mix.exs in Repository Twin for vulnerabilities" do
    # 1. Setup repository twin layout
    mix_content = """
    defmodule Twin.MixProject do
      use Mix.Project
      def project do
        [deps: [{:plug, "1.13.0"}]]
      end
    end
    """
    {:ok, twin_path} = RepositoryTwin.create_twin("mix_audit", %{"mix.exs" => mix_content})

    # 2. Define genome spec
    spec = %{rules: [%{package: "plug", vulnerable_before: "1.14.0"}]}
    genome = ToolGenomeEngine.generate_genome(
      :dep_scanner,
      :find_insecure_dependency,
      :repository_analysis,
      :interpreter,
      spec
    )

    # 3. Execute interpreter
    assert {:ok, %{vulnerabilities: [vuln]}} = ToolRuntime.execute_tool(genome, twin_path, %{})
    assert vuln.package == "plug"
    assert vuln.version == "1.13.0"
    assert vuln.status == "vulnerable"

    # Cleanup twin
    assert :ok = RepositoryTwin.cleanup_twin(twin_path)
  end

  test "Capability Failure Test: traps runtime crashes gracefully, records failure evidence, and penalizes fitness" do
    # Register genome in State
    genome = ToolGenomeEngine.generate_genome(
      :broken_scanner,
      :find_insecure_dependency,
      :repository_analysis,
      :interpreter,
      %{rules: []}
    )

    {:ok, _state} = CivilizationKernel.update_state(fn current_state ->
      %{current_state | tools: Map.put(current_state.tools, :broken_scanner, genome)}
    end)

    # Run loop on a non-existent path to trigger a file read crash
    non_existent_path = "scratch/non_existent_directory_xyz"

    assert {:error, {:runtime_crash, _}, failure_evidence} = 
      ToolRuntime.run_grounding_loop(genome, non_existent_path, %{}, :cybersecurity)

    # Verify failure evidence
    assert failure_evidence.validity == :invalid
    assert failure_evidence.value == 0.0
    assert failure_evidence.metadata.source == :tool_execution
    assert failure_evidence.metadata.genome_id == :broken_scanner

    # Verify state contains penalized genome fitness (initial 0.5 * 0.5 = 0.25)
    updated_state = CivilizationKernel.get_state()
    updated_genome = Map.get(updated_state.tools, :broken_scanner)
    assert updated_genome.fitness == 0.25
  end

  test "Security Profile Hook: blocks unauthorized profiles against strict kernel policy" do
    # Policy mode defaults to :strict in setup
    genome = ToolGenomeEngine.generate_genome(
      :insecure_tool,
      :find_insecure_dependency,
      :repository_analysis,
      :interpreter,
      %{},
      security_profile: %{read_sandbox: false} # Sandbox required under strict mode
    )

    assert {:error, {:security_violation, :untrusted_sandbox}} = 
      ToolRuntime.execute_tool(genome, "scratch/dummy", %{})

    # Test unauthorized network access
    genome_network = ToolGenomeEngine.generate_genome(
      :network_tool,
      :find_insecure_dependency,
      :repository_analysis,
      :interpreter,
      %{},
      security_profile: %{read_sandbox: true, network_access: true} # Network access forbidden
    )

    assert {:error, {:security_violation, :unauthorized_network_access}} = 
      ToolRuntime.execute_tool(genome_network, "scratch/dummy", %{})
  end

  test "End-to-End Grounding Loop: runs tool, records empirical evidence, and revises JTMS belief confidence" do
    # 1. Setup World structures
    theory = %EvidenceNode{id: :cyber_theory, type: :theory, name: "Cybersecurity Theory", value: 1.0, validity: :valid}
    claim = %EvidenceNode{id: :cyber_claim, type: :claim, name: "Claims plug is vulnerable", value: 1.0, validity: :valid}

    # Set up initial JTMS state
    {:ok, _state} = CivilizationKernel.update_state(fn current_state ->
      initial_graph =
        current_state.evidence_graph
        |> Map.put(:cyber_theory, theory)
        |> Map.put(:cyber_claim, claim)

      %{current_state | evidence_graph: initial_graph}
    end)

    # Link Theory -> Claim
    CivilizationKernel.update_state(fn current_state ->
      EvidenceEngine.add_relation(current_state, :cyber_theory, :predicts, :cyber_claim)
    end)

    # 2. Setup Twin codebase
    mix_content = """
    defmodule Twin.MixProject do
      use Mix.Project
      def project do
        [deps: [{:plug, "1.13.0"}]]
      end
    end
    """
    {:ok, twin_path} = RepositoryTwin.create_twin("grounding_loop", %{"mix.exs" => mix_content})

    # 3. Create tool genome
    spec = %{rules: [%{package: "plug", vulnerable_before: "1.14.0"}]}
    genome = ToolGenomeEngine.generate_genome(
      :e2e_scanner,
      :find_insecure_dependency,
      :repository_analysis,
      :interpreter,
      spec
    )

    # 4. Run Grounding Loop
    assert {:ok, evidence_node, state_after_run} = 
      ToolRuntime.run_grounding_loop(genome, twin_path, %{}, :cybersecurity)

    assert evidence_node.value == 1.0 # Vulnerability successfully found

    # 5. Link generated evidence node to Claim in the state graph
    state_after_run = EvidenceEngine.add_node(state_after_run, evidence_node)
    state_after_run = EvidenceEngine.add_relation(state_after_run, evidence_node.id, :supports, :cyber_claim)

    # Clean up Repository Twin files
    assert :ok = RepositoryTwin.cleanup_twin(twin_path)

    # Verify that the theory confidence has been recalculated (since claim and evidence are valid, confidence remains solid)
    theory_node = Map.get(state_after_run.evidence_graph, :cyber_theory)
    assert theory_node.value == 1.0

    # 6. Now refute the generated evidence node and observe the belief revision cascade!
    revised_state = EvidenceEngine.refute_evidence(state_after_run, evidence_node.id)

    # Assert that the claim confidence degraded (degraded by 0.7)
    claim_node = Map.get(revised_state.evidence_graph, :cyber_claim)
    assert_in_delta claim_node.value, 0.7, 0.001

    # Assert that the root theory confidence recalculated to the claim's degraded confidence (0.7)
    theory_node = Map.get(revised_state.evidence_graph, :cyber_theory)
    assert_in_delta theory_node.value, 0.7, 0.001
  end
end
