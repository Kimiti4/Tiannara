defmodule TiannaraRuntime.CrossDimensionalTest do
  use ExUnit.Case, async: false

  alias TiannaraRuntime.CrossDimensional.{BoundaryValidator, Compiler}

  test "boundary validator validates conservation and anchor constraints" do
    valid_op = %{
      cost_estimate: 0.5,
      anchors: ["anchor_1"]
    }

    invalid_cost_op = %{
      cost_estimate: 1.5,
      anchors: ["anchor_1"]
    }

    invalid_anchors_op = %{
      cost_estimate: 0.5,
      anchors: []
    }

    assert BoundaryValidator.validate(valid_op) == :ok
    assert BoundaryValidator.validate(invalid_cost_op) == {:error, :validation_failed}
    assert BoundaryValidator.validate(invalid_anchors_op) == {:error, :validation_failed}
  end

  test "compiler translates OPC AST into latent meta-op payload" do
    ast = %{
      id: "test_ast_rule",
      complexity: 4,
      anchors: ["anchor_1"],
      graph: %{
        nodes: ["node_1", "node_2"],
        edges: [{"node_1", "node_2"}]
      }
    }

    assert {:ok, meta_op} = Compiler.compile(ast)
    assert meta_op.id == "test_ast_rule"
    assert meta_op.cost_estimate == 0.4
    assert is_map(meta_op.latent_coordinates)
  end

  test "compiler rejects invalid boundary meta-op" do
    ast = %{
      id: "invalid_ast_rule",
      complexity: 20,
      anchors: ["anchor_1"],
      graph: %{
        nodes: ["node_1", "node_2"],
        edges: [{"node_1", "node_2"}]
      }
    }

    assert {:error, :validation_failed} = Compiler.compile(ast)
  end
end
