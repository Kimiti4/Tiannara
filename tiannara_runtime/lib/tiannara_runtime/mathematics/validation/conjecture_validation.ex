defmodule TiannaraRuntime.Mathematics.Validation.ConjectureValidation do
  @moduledoc """
  Phase 16.X.95 — Conjecture Validation Campaign

  Generates conjectures across all source generators, verifies deterministic
  priorities and clustering, and validates replay and archaeology.
  """

  @behaviour TiannaraRuntime.Mathematics.Validation.Campaign

  alias TiannaraRuntime.Mathematics.ConjectureEngine

  @impl true
  def name, do: "Conjecture Validation"

  @impl true
  def description, do: "Generate conjectures across all source generators, verify deterministic priorities, clustering, replay, and archaeology."

  @impl true
  def run(_opts \\ []) do
    checks = [
      check_all_sources(),
      check_deterministic_priorities(),
      check_clustering(),
      check_replay(),
      check_archaeology()
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

  defp check_all_sources do
    sources = ConjectureEngine.valid_sources()
    count = 100
    per_source = max(1, div(count, length(sources)))

    results = Enum.flat_map(sources, fn source ->
      Enum.map(1..per_source, fn i ->
        statement = "#{source}_conjecture_#{i}: The structure satisfies property Q"
        generator_opts = %{
          "source" => source,
          "dependencies" => ["dep_#{i}_#{source}"],
          "research_value" => 0.25 + (rem(i, 10) / 20.0),
          "uncertainty" => 0.1 + (rem(i, 10) / 12.5),
          "complexity" => rem(i, 5) + 1
        }

        ConjectureEngine.generate_conjecture(statement, generator_opts)
      end)
    end)

    successes = Enum.filter(results, fn r -> elem(r, 0) == :ok end)
    failures = Enum.filter(results, fn r -> elem(r, 0) == :error end)

    if failures == [] do
      %{check: "all_sources", status: :pass, detail: "#{length(successes)} conjectures generated from #{length(sources)} sources"}
    else
      %{check: "all_sources", status: :fail, detail: "#{length(failures)} failures: #{inspect(Enum.take(failures, 3))}"}
    end
  end

  defp check_deterministic_priorities do
    statements = [
      %{statement: "Every group of order p^2 is abelian", opts: %{"source" => "knowledge_gap", "novelty" => 0.8, "potential_impact" => 0.9}},
      %{statement: "Tensor product of vector spaces is associative", opts: %{"source" => "pattern", "novelty" => 0.3, "potential_impact" => 0.5}},
      %{statement: "The Riemann zeta function has all non-trivial zeros on critical line", opts: %{"source" => "counterexample", "novelty" => 0.9, "potential_impact" => 1.0}},
      %{statement: "Every continuous function on a compact set is uniformly continuous", opts: %{"source" => "generalization", "novelty" => 0.4, "potential_impact" => 0.6}},
      %{statement: "Graph coloring is NP-complete for planar graphs", opts: %{"source" => "specialization", "novelty" => 0.5, "potential_impact" => 0.7}}
    ]

    results = Enum.map(statements, fn s ->
      %{statement: stmt, opts: opts} = s
      first = ConjectureEngine.compute_priority(stmt, opts)

      rest = Enum.map(1..50, fn _ ->
        ConjectureEngine.compute_priority(stmt, opts)
      end)

      all_match = Enum.all?(rest, fn p -> p == first end)
      %{statement: String.slice(stmt, 0, 50), stable: all_match, priority: first}
    end)

    unstable = Enum.filter(results, fn r -> r[:stable] == false end)

    if unstable == [] do
      priorities = Enum.map(results, fn r -> r[:priority] end)
      %{check: "deterministic_priorities", status: :pass, detail: "5 statements, 50 re-computations each, all stable. Priorities: #{inspect(priorities)}"}
    else
      %{check: "deterministic_priorities", status: :fail, detail: "#{length(unstable)} unstable priorities"}
    end
  end

  defp check_clustering do
    cluster_statements = [
      %{statement: "Every group is a ring under some operation", known_clusters: ["algebra", "abstract_algebra"]},
      %{statement: "The manifold is compact and Hausdorff", known_clusters: ["topology", "geometry"]},
      %{statement: "Tensor product of algebras is associative", known_clusters: ["algebra", "abstract_algebra", "tensors"]},
      %{statement: "Convex optimization problem with linear constraints", known_clusters: ["optimization", "convex_analysis"]},
      %{statement: "Graph with vertices and edges is bipartite", known_clusters: ["graph_theory", "combinatorics"]},
      %{statement: "Entropy of information channel capacity", known_clusters: ["information_theory", "probability"]},
      %{statement: "Functor between categories preserves morphisms", known_clusters: ["category_theory", "abstract_algebra"]},
      %{statement: "Probability distribution of random variable", known_clusters: ["probability", "statistics"]}
    ]

    results = Enum.map(cluster_statements, fn %{statement: stmt, known_clusters: kcs} ->
      conjecture = elem(ConjectureEngine.generate_conjecture(stmt, %{"source" => "knowledge_gap"}), 1)
      actual = Map.get(conjecture, "cluster")
      match = actual in kcs
      %{statement: String.slice(stmt, 0, 50), known_clusters: kcs, actual: actual, match: match}
    end)

    mismatches = Enum.filter(results, fn r -> r[:match] == false end)

    if mismatches == [] do
      %{check: "clustering", status: :pass, detail: "8 statements clustered into known valid domains"}
    else
      %{check: "clustering", status: :fail, detail: "Cluster mismatches: #{inspect(mismatches)}"}
    end
  end

  defp check_replay do
    results = Enum.map(1..100, fn i ->
      sources = ConjectureEngine.valid_sources()
      source = Enum.at(sources, rem(i, length(sources)))
      statement = "Replay conjecture #{i}: Every #{source} structure has property R"
      opts = %{"source" => source, "cluster_hint" => Enum.at(ConjectureEngine.valid_clusters(), rem(i, 8))}

      with {:ok, original} <- ConjectureEngine.generate_conjecture(statement, opts),
           {:ok, replayed} <- ConjectureEngine.replay_conjecture(original) do
        ids_match = original["conjecture_id"] == replayed["conjecture_id"]
        priority_match = original["priority"] == replayed["priority"]
        cluster_match = original["cluster"] == replayed["cluster"]
        all_match = ids_match and priority_match and cluster_match
        %{iteration: i, match: all_match}
      else
        {:error, reason} -> %{iteration: i, match: false, error: reason}
      end
    end)

    mismatches = Enum.filter(results, fn r -> r[:match] == false end)

    if mismatches == [] do
      %{check: "replay", status: :pass, detail: "100 conjectures replayed, all ids/priorities/clusters match"}
    else
      %{check: "replay", status: :fail, detail: "#{length(mismatches)} mismatches"}
    end
  end

  defp check_archaeology do
    results = Enum.map(1..50, fn i ->
      statement = "Archaeology conjecture #{i}: property S is preserved under transformation T"
      with {:ok, conjecture} <- ConjectureEngine.generate_conjecture(statement, %{"source" => "knowledge_gap"}),
           {:ok, record} <- ConjectureEngine.archaeology(conjecture) do
        has_conjecture_id = Map.has_key?(record, "conjecture_id")
        has_why = Map.has_key?(record, "generated_why")
        has_origin = get_in(record, ["generated_why", "origin"]) != nil
        has_statement = Map.has_key?(record, "statement")
        completeness = has_conjecture_id and has_why and has_origin and has_statement
        %{iteration: i, complete: completeness}
      else
        {:error, reason} -> %{iteration: i, complete: false, error: reason}
      end
    end)

    complete = Enum.filter(results, fn r -> r[:complete] == true end)

    if length(complete) == length(results) do
      %{check: "archaeology", status: :pass, detail: "#{length(complete)}/#{length(results)} conjectures have complete archaeology records"}
    else
      %{check: "archaeology", status: :fail, detail: "#{length(results) - length(complete)} incomplete archaeology records"}
    end
  end
end
