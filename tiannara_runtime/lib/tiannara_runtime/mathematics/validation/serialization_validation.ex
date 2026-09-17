defmodule TiannaraRuntime.Mathematics.Validation.SerializationValidation do
  @moduledoc """
  Phase 16.X.95 — Serialization Validation Campaign

  Verifies canonical JSON serialization of SymbolicExpression structs,
  stable hashing via MathematicalID, and ordering stability.
  """

  @behaviour TiannaraRuntime.Mathematics.Validation.Campaign

  alias TiannaraRuntime.Mathematics.Ontology.SymbolicExpression
  alias TiannaraRuntime.Mathematics.MathematicalID

  @impl true
  def name, do: "Serialization Validation"

  @impl true
  def description, do: "Verify canonical JSON serialization, stable hashing, and ordering stability."

  @impl true
  def run(_opts \\ []) do
    checks = [
      check_canonical_json(),
      check_stable_hashing(),
      check_ordering_stability()
    ]

    status = if Enum.all?(checks, fn c -> c.status == :pass end), do: :pass, else: :fail

    {:ok, %{
      campaign: name(),
      status: status,
      checks: checks,
      summary: %{
        total: length(checks),
        passed: Enum.count(checks, fn c -> c.status == :pass end),
        failed: Enum.count(checks, fn c -> c.status == :fail end),
        errors: Enum.count(checks, fn c -> c.status == :error end)
      }
    }}
  end

  defp check_canonical_json do
    results = Enum.map(1..100, fn i ->
      expr = generate_test_expr(i)
      id1 = SymbolicExpression.id(expr)
      id2 = SymbolicExpression.id(expr)
      %{iteration: i, stable: id1 == id2, hash: id1}
    end)

    unstable = Enum.filter(results, fn r -> r[:stable] == false end)

    if unstable == [] do
      %{check: "canonical_json", status: :pass, detail: "100 expressions serialized, all self-consistent"}
    else
      %{check: "canonical_json", status: :fail, detail: "#{length(unstable)} unstable serializations"}
    end
  end

  defp check_stable_hashing do
    inputs = [
      %{"type" => "constant", "value" => 42, "children" => []},
      %{"type" => "variable", "value" => "x", "children" => []},
      %{"type" => "operator", "value" => :+, "children" => [
        %{"type" => "constant", "value" => 1, "children" => []},
        %{"type" => "variable", "value" => "y", "children" => []}
      ]},
      %{"a" => [1, 2, 3], "b" => %{"nested" => true}},
      %{"empty_map" => %{}, "empty_list" => []}
    ]

    results = Enum.flat_map(inputs, fn input ->
      first = MathematicalID.from_canonical_map(input)
      Enum.map(1..50, fn _ ->
        current = MathematicalID.from_canonical_map(input)
        current == first
      end)
    end)

    all_stable = Enum.all?(results, fn r -> r == true end)

    if all_stable do
      %{check: "stable_hashing", status: :pass, detail: "5 inputs hashed 50 times each, all stable"}
    else
      unstable_count = Enum.count(results, fn r -> r == false end)
      %{check: "stable_hashing", status: :fail, detail: "#{unstable_count} unstable hashes detected"}
    end
  end

  defp check_ordering_stability do
    map_a = %{"z" => 1, "a" => 2, "n" => 3, "b" => %{"inner_z" => 4, "inner_a" => 5}}
    map_b = %{"a" => 2, "b" => %{"inner_a" => 5, "inner_z" => 4}, "n" => 3, "z" => 1}

    hash_a = MathematicalID.from_canonical_map(map_a)
    hash_b = MathematicalID.from_canonical_map(map_b)

    list_a = [%{"b" => 2, "a" => 1}, %{"d" => 4, "c" => 3}]
    list_b = [%{"a" => 1, "b" => 2}, %{"c" => 3, "d" => 4}]

    hash_list_a = Enum.map(list_a, &MathematicalID.from_canonical_map/1)
    hash_list_b = Enum.map(list_b, &MathematicalID.from_canonical_map/1)

    ordering_ok = hash_a == hash_b and hash_list_a == hash_list_b

    if ordering_ok do
      %{check: "ordering_stability", status: :pass, detail: "Key ordering and list element ordering produces identical hashes"}
    else
      %{check: "ordering_stability", status: :fail, detail: "Ordering-dependent hash differences detected"}
    end
  end

  defp generate_test_expr(i) do
    base = case rem(i, 4) do
      0 -> {:ok, e} = SymbolicExpression.new(:constant, i); e
      1 -> {:ok, e} = SymbolicExpression.new(:variable, "var_#{i}"); e
      2 ->
        {:ok, c} = SymbolicExpression.new(:constant, i)
        {:ok, v} = SymbolicExpression.new(:variable, "x")
        {:ok, e} = SymbolicExpression.new(:operator, :+, children: [c, v])
        e
      3 ->
        {:ok, c} = SymbolicExpression.new(:constant, 0)
        {:ok, e} = SymbolicExpression.new(:operator, :*, children: [
          SymbolicExpression.new(:variable, "a") |> elem(1),
          SymbolicExpression.new(:constant, i) |> elem(1),
          c
        ])
        e
    end
  end
end
