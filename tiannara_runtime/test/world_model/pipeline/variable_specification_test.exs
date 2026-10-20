defmodule TiannaraRuntime.WorldModel.Pipeline.VariableSpecificationTest do
  use ExUnit.Case, async: true

  alias TiannaraRuntime.WorldModel.Pipeline.VariableSpecification

  describe "specify_variables/1" do
    test "returns empty variables from empty evidence" do
      {:ok, result} = VariableSpecification.specify_variables(%{observations: []})
      assert result.variables == []
      assert byte_size(result.variable_root) == 64
    end

    test "infers continuous variables from numeric payloads" do
      evidence = %{
        observations: [
          %{"payload" => %{"temperature" => 25.0, "pressure" => 1013}},
          %{"payload" => %{"temperature" => 30.0, "pressure" => 1015}}
        ]
      }

      {:ok, result} = VariableSpecification.specify_variables(evidence)
      assert length(result.variables) == 2

      temp = Enum.find(result.variables, fn v -> v.name == "temperature" end)
      assert temp.type == :continuous
      assert temp.domain == {25.0, 30.0}

      pres = Enum.find(result.variables, fn v -> v.name == "pressure" end)
      assert pres.type == :continuous
      assert pres.domain == {1013, 1015}
    end

    test "infers categorical variables from string payloads" do
      evidence = %{
        observations: [
          %{"payload" => %{"color" => "red", "shape" => "circle"}},
          %{"payload" => %{"color" => "blue", "shape" => "square"}}
        ]
      }

      {:ok, result} = VariableSpecification.specify_variables(evidence)
      color = Enum.find(result.variables, fn v -> v.name == "color" end)
      assert color.type == :categorical
      assert color.domain == ["blue", "red"]

      shape = Enum.find(result.variables, fn v -> v.name == "shape" end)
      assert shape.type == :categorical
      assert shape.domain == ["circle", "square"]
    end

    test "infers categorical from boolean values" do
      evidence = %{
        observations: [
          %{"payload" => %{"flag" => true}},
          %{"payload" => %{"flag" => false}}
        ]
      }

      {:ok, result} = VariableSpecification.specify_variables(evidence)
      flag = Enum.find(result.variables, fn v -> v.name == "flag" end)
      assert flag.type == :categorical
    end

    test "handles mixed types as categorical" do
      evidence = %{
        observations: [
          %{"payload" => %{"mixed" => 42}},
          %{"payload" => %{"mixed" => "hello"}}
        ]
      }

      {:ok, result} = VariableSpecification.specify_variables(evidence)
      mixed = Enum.find(result.variables, fn v -> v.name == "mixed" end)
      assert mixed.type == :categorical
    end

    test "handles nil observations gracefully" do
      {:ok, result} = VariableSpecification.specify_variables(%{})
      assert result.variables == []
    end

    test "handles observations with :atom keys" do
      evidence = %{
        observations: [
          %{:payload => %{"x" => 1.0}},
          %{:payload => %{"x" => 2.0}}
        ]
      }

      {:ok, result} = VariableSpecification.specify_variables(evidence)
      assert length(result.variables) == 1
      assert hd(result.variables).name == "x"
    end

    test "sets endogenous by default" do
      evidence = %{
        observations: [
          %{"payload" => %{"x" => 1}}
        ]
      }

      {:ok, result} = VariableSpecification.specify_variables(evidence)
      assert hd(result.variables).is_endogenous == true
    end

    test "variable_root is deterministic" do
      e1 = %{observations: [%{"payload" => %{"a" => 1, "b" => 2}}]}
      e2 = %{observations: [%{"payload" => %{"b" => 2, "a" => 1}}]}

      {:ok, r1} = VariableSpecification.specify_variables(e1)
      {:ok, r2} = VariableSpecification.specify_variables(e2)
      assert r1.variable_root == r2.variable_root
    end

    test "variable_root changes when schema changes" do
      e1 = %{observations: [%{"payload" => %{"a" => 1}}]}
      e2 = %{observations: [%{"payload" => %{"b" => 2}}]}

      {:ok, r1} = VariableSpecification.specify_variables(e1)
      {:ok, r2} = VariableSpecification.specify_variables(e2)
      refute r1.variable_root == r2.variable_root
    end

    test "creates variable_ids for each variable" do
      evidence = %{
        observations: [
          %{"payload" => %{"x" => 1, "y" => 2}}
        ]
      }

      {:ok, result} = VariableSpecification.specify_variables(evidence)
      for v <- result.variables do
        assert String.starts_with?(v.variable_id, "var_")
      end
    end
  end

  describe "extract_all_payload_keys/1" do
    test "extracts sorted unique keys" do
      obs = [
        %{"payload" => %{"b" => 1, "a" => 2}},
        %{"payload" => %{"c" => 3}}
      ]

      assert VariableSpecification.extract_all_payload_keys(obs) == ["a", "b", "c"]
    end

    test "returns empty list for empty observations" do
      assert VariableSpecification.extract_all_payload_keys([]) == []
    end
  end

  describe "collect_values_for_key/2" do
    test "collects all values for a key" do
      obs = [
        %{"payload" => %{"x" => 1}},
        %{"payload" => %{"x" => 2}}
      ]

      assert VariableSpecification.collect_values_for_key(obs, "x") == [1, 2]
    end

    test "filters out nils" do
      obs = [
        %{"payload" => %{"x" => 1}},
        %{"payload" => %{"y" => 2}}
      ]

      assert VariableSpecification.collect_values_for_key(obs, "x") == [1]
    end
  end

  describe "infer_variable/2" do
    test "creates variable with correct name" do
      {:ok, v} = VariableSpecification.infer_variable("temperature", [25.0, 30.0])
      assert v.name == "temperature"
    end

    test "continuous from numbers" do
      {:ok, v} = VariableSpecification.infer_variable("x", [1, 2, 3])
      assert v.type == :continuous
    end

    test "categorical from strings" do
      {:ok, v} = VariableSpecification.infer_variable("color", ["red", "blue"])
      assert v.type == :categorical
    end

    test "empty values default to continuous" do
      {:ok, v} = VariableSpecification.infer_variable("empty", [])
      assert v.type == :continuous
      assert v.domain == nil
    end
  end

  describe "compute_variable_root/1" do
    test "returns deterministic root" do
      vs = [
        {:ok, v1} = VariableSpecification.infer_variable("a", [1]),
        {:ok, _v2} = VariableSpecification.infer_variable("b", [2])
      ]

      r1 = VariableSpecification.compute_variable_root(Enum.map(vs, fn {:ok, v} -> v end))
      r2 = VariableSpecification.compute_variable_root(Enum.map(vs, fn {:ok, v} -> v end))
      assert r1 == r2
      assert byte_size(r1) == 64
    end
  end
end
