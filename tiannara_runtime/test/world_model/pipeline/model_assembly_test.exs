defmodule TiannaraRuntime.WorldModel.Pipeline.ModelAssemblyTest do
  use ExUnit.Case, async: false

  alias TiannaraRuntime.WorldModel.Pipeline.ModelAssembly
  alias TiannaraRuntime.WorldModel.ModelRegistry
  alias TiannaraRuntime.WorldModel.Ontology.{Variable, CausalGraph, CausalNode, Equation, EquationSystem}

  setup do
    ModelRegistry.reset_table()
    :ok
  end

  defp sample_variables do
    {:ok, v1} = Variable.new(variable_id: "v_x", name: "x", type: :continuous, domain: {0, 100}, unit: "m")
    {:ok, v2} = Variable.new(variable_id: "v_y", name: "y", type: :continuous, domain: {0, 50}, unit: "s")
    [v1, v2]
  end

  defp sample_graph(variables) do
    nodes = Enum.map(variables, fn v ->
      {:ok, n} = CausalNode.new(node_id: v.variable_id, type: :endogenous)
      n
    end)

    {:ok, cg} = CausalGraph.new(nodes: nodes, edges: [])
    cg
  end

  defp sample_equations(variables) do
    Enum.map(variables, fn v ->
      {:ok, eq} = Equation.new(
        target_variable: v.variable_id,
        expression: %{"form" => "constant", "parameters" => ["baseline"]},
        type: :algebraic
      )
      eq
    end)
  end

  describe "assemble_model/1" do
    test "creates and registers a world model" do
      vars = sample_variables()
      components = %{
        name: "Test Model",
        domain: :physics,
        variables: vars,
        causal_graph: sample_graph(vars),
        equation_system: EquationSystem.new(equations: sample_equations(vars)) |> elem(1),
        parameters: [],
        evidence_roots: ["ev_root_abc"],
        metadata: %{source: "test"},
        variable_root: "vr_abc",
        structure_root: "sr_abc",
        equation_root: "er_abc",
        parameter_root: "pr_abc"
      }

      {:ok, model} = ModelAssembly.assemble_model(components)
      assert model.name == "Test Model"
      assert model.domain == :physics
      assert model.status == :draft
      assert is_binary(model.model_id)
      assert is_binary(model.fingerprint)
      assert length(model.variables) == 2
      assert length(model.evidence_roots) == 1
    end

    test "registers in ModelRegistry" do
      vars = sample_variables()
      components = %{
        name: "Registered Model",
        domain: :physics,
        variables: vars,
        causal_graph: sample_graph(vars),
        equation_system: EquationSystem.new(equations: sample_equations(vars)) |> elem(1),
        evidence_roots: ["ev_root_def"]
      }

      {:ok, model} = ModelAssembly.assemble_model(components)
      {:ok, fetched} = ModelRegistry.get_model(model.model_id, model.version)
      assert fetched.model_id == model.model_id
      assert fetched.name == "Registered Model"
    end

    test "rejects missing name" do
      assert {:error, _} = ModelAssembly.assemble_model(%{domain: :physics})
    end

    test "rejects missing domain" do
      assert {:error, _} = ModelAssembly.assemble_model(%{name: "No Domain"})
    end

    test "builds state_space from variables" do
      vars = sample_variables()
      components = %{
        name: "State Space Test",
        domain: :physics,
        variables: vars
      }

      {:ok, model} = ModelAssembly.assemble_model(components)
      assert model.state_space.dimensions == 2
      assert model.state_space.variable_order == ["v_x", "v_y"]
      assert model.state_space.support_type == :continuous
    end

    test "fingerprint is deterministic for same roots" do
      roots = %{variable_root: "vr_x", structure_root: "sr_y"}
      f1 = ModelAssembly.compute_model_fingerprint(roots)
      f2 = ModelAssembly.compute_model_fingerprint(roots)
      assert f1 == f2
    end

    test "fingerprint changes when components differ" do
      vars1 = sample_variables()
      {:ok, v_extra} = Variable.new(name: "z", type: :continuous)
      vars2 = vars1 ++ [v_extra]

      {:ok, m1} = ModelAssembly.assemble_model(%{
        name: "M1", domain: :physics, variables: vars1,
        variable_root: "vr_a", structure_root: "sr_a"
      })
      {:ok, m2} = ModelAssembly.assemble_model(%{
        name: "M2", domain: :physics, variables: vars2,
        variable_root: "vr_b", structure_root: "sr_b"
      })
      refute m1.fingerprint == m2.fingerprint
    end
  end

  describe "build_state_space/1" do
    test "creates state space with correct dimensions" do
      {:ok, v1} = Variable.new(name: "x", type: :continuous)
      {:ok, v2} = Variable.new(name: "y", type: :continuous)

      ss = ModelAssembly.build_state_space([v1, v2])
      assert ss.dimensions == 2
      assert length(ss.variable_order) == 2
    end

    test "builds bounds from variable domains" do
      {:ok, v1} = Variable.new(variable_id: "v_x", name: "x", type: :continuous, domain: {0, 100})
      {:ok, v2} = Variable.new(variable_id: "v_y", name: "y", type: :categorical, domain: ["a", "b"])

      bounds = ModelAssembly.build_bounds_map([v1, v2])
      assert bounds["v_x"] == {0, 100}
      assert bounds["v_y"] == ["a", "b"]
    end
  end

  describe "infer_support_type/1" do
    test "all continuous" do
      {:ok, v1} = Variable.new(name: "x", type: :continuous)
      {:ok, v2} = Variable.new(name: "y", type: :continuous)
      assert ModelAssembly.infer_support_type([v1, v2]) == :continuous
    end

    test "mixed types" do
      {:ok, v1} = Variable.new(name: "x", type: :continuous)
      {:ok, v2} = Variable.new(name: "y", type: :ordinal)
      assert ModelAssembly.infer_support_type([v1, v2]) == :mixed
    end

    test "all discrete" do
      {:ok, v1} = Variable.new(name: "x", type: :ordinal)
      {:ok, v2} = Variable.new(name: "y", type: :ordinal)
      assert ModelAssembly.infer_support_type([v1, v2]) == :discrete
    end
  end

  describe "compute_model_fingerprint/1" do
    test "returns deterministic fingerprint" do
      roots = %{variable_root: "vr_a", structure_root: "sr_b"}
      f1 = ModelAssembly.compute_model_fingerprint(roots)
      f2 = ModelAssembly.compute_model_fingerprint(roots)
      assert f1 == f2
      assert byte_size(f1) == 64
    end

    test "filters out nil roots" do
      f = ModelAssembly.compute_model_fingerprint(%{variable_root: "vr_a", equation_root: nil})
      assert byte_size(f) == 64
    end
  end
end
