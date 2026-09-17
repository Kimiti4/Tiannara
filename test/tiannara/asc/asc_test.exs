defmodule Tiannara.ASC.ASCTest do
  use ExUnit.Case, async: false

  setup do
    start_supervised!({Tiannara.ASC.KnowledgeEconomy, name: :test_ke})
    start_supervised!({Tiannara.ASC.CivilizationManager, name: :test_civ_mgr})
    start_supervised!({Tiannara.ASC.CapabilityEvolution, name: :test_cap_ev})
    start_supervised!({Tiannara.ASC.InstitutionEngine, name: :test_inst_eng})
    start_supervised!({Tiannara.ASC.ResourceAllocator, name: :test_res_alloc})
    start_supervised!({Tiannara.ASC.ResearchPlanner, name: :test_res_plan})
    start_supervised!({Tiannara.ASC.CivilizationMemory, name: :test_civ_mem})
    start_supervised!({Tiannara.ASC.CivilizationMetrics, name: :test_civ_met})
    :ok
  end

  describe "functional: knowledge compounds" do
    test "discovery becomes validated knowledge asset" do
      discovery = %{
        id: "d1",
        domain: :materials,
        content: "New alloy composition",
        confidence: 0.7
      }

      {:ok, asset} = Tiannara.ASC.KnowledgeEconomy.ingest_discovery(:test_ke, discovery)
      assert asset.validation_status == :pending_validation

      evidence = [%{id: "e1", quality: 0.9, contradicts_asset: nil}]

      {:ok, validated} =
        Tiannara.ASC.KnowledgeEconomy.validate_asset(:test_ke, asset.id, evidence)

      assert validated.validation_status == :validated
      assert validated.confidence > 0.7
    end

    test "validated assets are retrievable by domain" do
      {:ok, asset} =
        Tiannara.ASC.KnowledgeEconomy.ingest_discovery(:test_ke, %{
          id: "d2",
          domain: :physics,
          content: "String theory refinement",
          confidence: 0.8
        })

      Tiannara.ASC.KnowledgeEconomy.validate_asset(:test_ke, asset.id, [
        %{id: "e2", quality: 0.9, contradicts_asset: nil}
      ])

      assets = Tiannara.ASC.KnowledgeEconomy.get_assets(:test_ke, :physics)
      assert length(assets) > 0
    end
  end

  describe "functional: civilizations form and specialize" do
    test "default civilizations exist" do
      civs = Tiannara.ASC.CivilizationManager.list_civilizations(:test_civ_mgr)
      assert length(civs) == 9
      domains = Enum.map(civs, & &1.domain)
      assert :mathematics in domains
      assert :robotics in domains
      assert :governance in domains
    end

    test "new civilizations can be created" do
      {:ok, civ} = Tiannara.ASC.CivilizationManager.form_civilization(:test_civ_mgr, :biology)
      assert civ.domain == :biology
      assert civ.status == :active
    end

    test "duplicate civilization returns exists" do
      {:exists, _civ} =
        Tiannara.ASC.CivilizationManager.form_civilization(:test_civ_mgr, :physics)
    end
  end

  describe "functional: capabilities evolve and compete" do
    test "higher fitness capabilities are promoted" do
      {:ok, cap_a} =
        Tiannara.ASC.CapabilityEvolution.propose_capability(:test_cap_ev, %{
          name: "Tech A",
          domain: :energy,
          innovation: 0.9,
          efficiency: 0.9,
          scalability: 0.9,
          civilizational_value: 0.9,
          cost: 0.2
        })

      {:ok, cap_b} =
        Tiannara.ASC.CapabilityEvolution.propose_capability(:test_cap_ev, %{
          name: "Tech B",
          domain: :energy,
          innovation: 0.3,
          efficiency: 0.3,
          scalability: 0.3,
          civilizational_value: 0.3,
          cost: 0.9
        })

      selected = Tiannara.ASC.CapabilityEvolution.select_capabilities(:test_cap_ev, :energy)
      assert Enum.any?(selected, &(&1.id == cap_a.id))
      assert Enum.all?(selected, &(&1.status == :promoted))
    end

    test "capability has fitness calculated from attrs" do
      {:ok, cap} =
        Tiannara.ASC.CapabilityEvolution.propose_capability(:test_cap_ev, %{
          name: "Test Cap",
          domain: :engineering,
          innovation: 0.5,
          efficiency: 0.5,
          scalability: 0.5,
          civilizational_value: 0.5,
          cost: 0.5
        })

      assert cap.fitness > 0
      assert cap.lineage_id != nil
    end
  end

  describe "functional: institutions form from successful patterns" do
    test "institution proposed and evaluated" do
      {:ok, inst} =
        Tiannara.ASC.InstitutionEngine.propose_institution(:test_inst_eng, %{
          name: "Energy Research Institute",
          civilization_id: "civ_1",
          purpose: "Advance energy capabilities",
          capabilities: [],
          knowledge: [],
          founding_discovery_id: "d_1"
        })

      assert inst.status == :proposed

      {:ok, evaluated} =
        Tiannara.ASC.InstitutionEngine.evaluate_institution(:test_inst_eng, inst.id)

      assert evaluated.status == :active
    end
  end

  describe "functional: resource allocation" do
    test "allocates resources based on priority" do
      program = %{id: "p1", confidence: 0.7}

      {:approved, allocation} =
        Tiannara.ASC.ResourceAllocator.allocate(:test_res_alloc, program, 100)

      assert allocation.approval_status == :pending_human_approval
    end

    test "insufficient budget returns error" do
      program = %{id: "p2", confidence: 0.5}
      Tiannara.ASC.ResourceAllocator.allocate(:test_res_alloc, program, 900)

      {:insufficient_resources, _allocation} =
        Tiannara.ASC.ResourceAllocator.allocate(:test_res_alloc, program, 200)
    end
  end

  describe "functional: research planning" do
    test "decomposes goal into programs" do
      {:ok, _plan_id, programs} =
        Tiannara.ASC.ResearchPlanner.plan(:test_res_plan, "Improve renewable energy")

      assert length(programs) == 4
      domains = Enum.map(programs, & &1.domain)
      assert :materials in domains
      assert :engineering in domains
    end
  end

  describe "functional: civilization memory" do
    test "preserves discoveries and failures" do
      Tiannara.ASC.CivilizationMemory.preserve(:test_civ_mem, %{
        type: :discovery,
        id: "d_arch_1",
        domain: :physics,
        content: "Breakthrough"
      })

      Tiannara.ASC.CivilizationMemory.preserve(:test_civ_mem, %{
        type: :failure,
        id: "f_arch_1",
        domain: :physics,
        content: "Failed attempt"
      })

      discoveries =
        Tiannara.ASC.CivilizationMemory.retrieve(:test_civ_mem, %{
          type: :discovery,
          domain: :physics
        })

      assert length(discoveries) == 1

      failures =
        Tiannara.ASC.CivilizationMemory.retrieve(:test_civ_mem, %{
          type: :failure,
          domain: :physics
        })

      assert length(failures) == 1
    end
  end

  describe "evolution: knowledge growth over cycles" do
    test "knowledge growth and diversity measurable after cycles" do
      for i <- 1..100 do
        Tiannara.ASC.KnowledgeEconomy.ingest_discovery(:test_ke, %{
          id: "d_#{i}",
          domain: Enum.random([:mathematics, :physics, :engineering, :robotics]),
          content: "Discovery #{i}",
          confidence: :rand.uniform()
        })
      end

      metrics = Tiannara.ASC.CivilizationMetrics.measure(:test_civ_met)
      assert metrics.knowledge_growth.new_validated >= 0
      assert metrics.diversity.active_lineages > 0
    end
  end

  describe "adversarial: handles monoculture risk" do
    test "diversity metric reflects domain imbalance" do
      for i <- 1..50 do
        Tiannara.ASC.KnowledgeEconomy.ingest_discovery(:test_ke, %{
          id: "mono_#{i}",
          domain: :mathematics,
          content: "Math discovery #{i}",
          confidence: 0.8
        })
      end

      metrics = Tiannara.ASC.CivilizationMetrics.measure(:test_civ_met)
      assert metrics.diversity.domain_coverage < 1.0
    end
  end

  describe "adversarial: contradictory evidence" do
    test "contradictions reduce confidence" do
      {:ok, asset} =
        Tiannara.ASC.KnowledgeEconomy.ingest_discovery(:test_ke, %{
          id: "d_contra",
          domain: :physics,
          content: "Controversial theory",
          confidence: 0.8
        })

      evidence = [
        %{id: "e1", quality: 0.9, contradicts_asset: asset.id},
        %{id: "e2", quality: 0.8, contradicts_asset: asset.id}
      ]

      {:ok, validated} =
        Tiannara.ASC.KnowledgeEconomy.validate_asset(:test_ke, asset.id, evidence)

      assert validated.confidence < 0.8
      assert length(validated.contradictions) == 2
    end
  end

  describe "constitutional: verification first" do
    test "resource allocation requires human approval" do
      program = %{id: "p_con_1", confidence: 0.7}

      {:approved, allocation} =
        Tiannara.ASC.ResourceAllocator.allocate(:test_res_alloc, program, 50)

      assert allocation.approval_status == :pending_human_approval
    end

    test "institutions steward capabilities and knowledge" do
      {:ok, inst} =
        Tiannara.ASC.InstitutionEngine.propose_institution(:test_inst_eng, %{
          name: "Verification Institute",
          civilization_id: "civ_2",
          purpose: "Test verification",
          capabilities: ["cap_1", "cap_2"],
          knowledge: ["ka_1"],
          founding_discovery_id: "d_v_1"
        })

      assert length(inst.capabilities_managed) == 2
      assert length(inst.knowledge_stewarded) == 1
    end
  end
end
