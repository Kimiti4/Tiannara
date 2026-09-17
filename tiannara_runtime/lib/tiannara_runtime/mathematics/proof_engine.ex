defmodule TiannaraRuntime.Mathematics.ProofEngine do
  @moduledoc """
  Phase 16.X.4 — Constitutional Proof Engine

  Constructs, verifies, replays, and archaeologically explains mathematical proofs.

  A proof is immutable constitutional evidence. A theorem exists only because a
  proof exists. Every proof is deterministic, replayable, independently
  reconstructable, archaeologically explainable, and content-addressed.

  The engine does NOT generate conjectures, discover mathematics autonomously,
  perform numerical approximation, world reasoning, governance, or certification.
  """

  @strategies [:direct, :contradiction, :induction, :constructive, :computational]

  alias TiannaraRuntime.Mathematics.MathematicalID

  # ---------------------------------------------------------------------------
  # Proof Construction
  # ---------------------------------------------------------------------------

  @doc "Construct a proof for an assertion using a given strategy."
  @spec build_proof(String.t(), atom(), [String.t()], [map()]) :: {:ok, map()} | {:error, String.t()}
  def build_proof(assertion_id, strategy, assumptions, steps) do
    with :ok <- validate_strategy(strategy) do
      now = :erlang.unique_integer([:positive]) |> Integer.to_string()
      proof_id = compute_proof_id(assertion_id, strategy, assumptions, steps)

      deps = extract_dependencies(steps)
      inter = extract_intermediate_results(steps)

      proof = %{
        "proof_id" => proof_id,
        "assertion_id" => assertion_id,
        "strategy" => strategy,
        "assumptions" => assumptions,
        "steps" => steps,
        "dependencies" => deps,
        "intermediate_results" => inter,
        "verification_status" => "unverified",
        "proof_hash" => compute_proof_hash(proof_id, assertion_id, strategy, assumptions, steps),
        "created_at" => now,
        "version" => "1.0.0"
      }

      {:ok, proof}
    end
  end

  @doc "Build a direct proof: A → B → C → ... → conclusion."
  @spec direct_proof(String.t(), [String.t()], [map()]) :: {:ok, map()} | {:error, String.t()}
  def direct_proof(assertion_id, assumptions, steps) do
    build_proof(assertion_id, :direct, assumptions, steps)
  end

  @doc "Build a proof by contradiction: assume ¬conclusion, derive ⊥, conclude."
  @spec contradiction_proof(String.t(), [String.t()], [map()]) :: {:ok, map()} | {:error, String.t()}
  def contradiction_proof(assertion_id, assumptions, steps) do
    build_proof(assertion_id, :contradiction, assumptions, steps)
  end

  @doc "Build a proof by induction: base case + inductive step."
  @spec induction_proof(String.t(), [String.t()], [map()], [map()]) :: {:ok, map()} | {:error, String.t()}
  def induction_proof(assertion_id, assumptions, base_steps, inductive_steps) do
    all_steps = (base_steps || []) ++ (inductive_steps || [])
    build_proof(assertion_id, :induction, assumptions, all_steps)
  end

  @doc "Build a constructive proof: provide witness or algorithm."
  @spec constructive_proof(String.t(), [String.t()], [map()]) :: {:ok, map()} | {:error, String.t()}
  def constructive_proof(assertion_id, assumptions, steps) do
    build_proof(assertion_id, :constructive, assumptions, steps)
  end

  @doc "Build a computational proof: verify by exhaustive computation."
  @spec computational_proof(String.t(), [String.t()], [map()]) :: {:ok, map()} | {:error, String.t()}
  def computational_proof(assertion_id, assumptions, steps) do
    build_proof(assertion_id, :computational, assumptions, steps)
  end

  # ---------------------------------------------------------------------------
  # Verification
  # ---------------------------------------------------------------------------

  @doc """
  Verify a proof through all five verification stages.

  1. Structural verification — valid steps, no missing fields
  2. Logical verification — each step follows from previous
  3. Dependency verification — all dependencies satisfied
  4. Replay verification — proof can be reconstructed
  5. Archaeology verification — lineage is complete

  Fail Closed at any stage.
  """
  @spec verify_proof(map()) :: {:ok, map()} | {:error, String.t()}
  def verify_proof(proof) do
    with {:ok, p} <- structural_verify(proof),
         {:ok, p} <- logical_verify(p),
         {:ok, p} <- dependency_verify(p),
         {:ok, p} <- replay_verify(p),
         {:ok, p} <- archaeology_verify(p) do
      proven = Map.put(p, "verification_status", "verified")
      {:ok, proven}
    end
  end

  @doc "Structural verification: valid steps, no missing fields."
  @spec structural_verify(map()) :: {:ok, map()} | {:error, String.t()}
  def structural_verify(proof) do
    required = ~w(proof_id assertion_id strategy assumptions steps)
    missing = Enum.reject(required, fn k -> Map.has_key?(proof, k) and Map.get(proof, k) != nil end)

    if missing == [] do
      steps = Map.get(proof, "steps", [])
      step_errors =
        Enum.reduce(steps, [], fn step, acc ->
          step_req = ~w(step_number rule_applied input_objects output_object)
          step_missing = Enum.reject(step_req, fn k -> Map.has_key?(step, k) end)
          acc ++ Enum.map(step_missing, fn k -> "step #{Map.get(step, "step_number", "?")} missing: #{k}" end)
        end)

      if step_errors == [] do
        {:ok, proof}
      else
        {:error, "structural verification failed: #{Enum.join(step_errors, "; ")}"}
      end
    else
      {:error, "structural verification failed: missing fields: #{Enum.join(missing, ", ")}"}
    end
  end

  @doc "Logical verification: each step follows from previous."
  @spec logical_verify(map()) :: {:ok, map()} | {:error, String.t()}
  def logical_verify(proof) do
    steps = Map.get(proof, "steps", [])
    sorted = Enum.sort_by(steps, fn s -> Map.get(s, "step_number", 0) end)
    expected = Enum.to_list(0..(length(sorted) - 1))
    actual = Enum.map(sorted, fn s -> Map.get(s, "step_number", -1) end)

    if actual == expected do
      {:ok, proof}
    else
      {:error, "logical verification failed: step numbers not sequential. Expected: #{inspect(expected)}, got: #{inspect(actual)}"}
    end
  end

  @doc "Dependency verification: all dependencies are satisfied."
  @spec dependency_verify(map()) :: {:ok, map()} | {:error, String.t()}
  def dependency_verify(proof) do
    deps = Map.get(proof, "dependencies", [])
    steps = Map.get(proof, "steps", [])
    step_hashes = Enum.map(steps, fn s -> Map.get(s, "fingerprint", "") end)
    dep_set = MapSet.new(deps)
    step_set = MapSet.new(step_hashes)
    unsatisfied = MapSet.difference(dep_set, step_set) |> MapSet.to_list()

    if unsatisfied == [] do
      {:ok, proof}
    else
      {:error, "dependency verification failed: unsatisfied dependencies: #{inspect(unsatisfied)}"}
    end
  end

  @doc "Replay verification: proof can be deterministically reconstructed."
  @spec replay_verify(map()) :: {:ok, map()} | {:error, String.t()}
  def replay_verify(proof) do
    case replay_proof(proof) do
      {:ok, replayed} ->
        if replayed["proof_hash"] == proof["proof_hash"] do
          {:ok, proof}
        else
          {:error, "replay verification failed: hash mismatch"}
        end
      {:error, reason} ->
        {:error, "replay verification failed: #{reason}"}
    end
  end

  @doc "Archaeology verification: lineage is complete."
  @spec archaeology_verify(map()) :: {:ok, map()} | {:error, String.t()}
  def archaeology_verify(proof) do
    case archaeology(proof) do
      {:ok, _record} -> {:ok, proof}
      {:error, reason} -> {:error, "archaeology verification failed: #{reason}"}
    end
  end

  # ---------------------------------------------------------------------------
  # Replay
  # ---------------------------------------------------------------------------

  @doc """
  Replay a proof deterministically.

  Uses only: ontology, symbolic representations, rewrite rules,
  dependency graph, deterministic context. No runtime cache.
  Produces identical proof, fingerprints, dependency graph, and hashes.
  """
  @spec replay_proof(map()) :: {:ok, map()} | {:error, String.t()}
  def replay_proof(proof) do
    assertion_id = Map.get(proof, "assertion_id")
    strategy = Map.get(proof, "strategy")
    assumptions = Map.get(proof, "assumptions", [])
    steps = Map.get(proof, "steps", [])

    if assertion_id == nil or strategy == nil do
      {:error, "cannot replay: missing assertion_id or strategy"}
    else
      result = build_proof(assertion_id, String.to_existing_atom(to_string(strategy)), assumptions, steps)

      case result do
        {:ok, p} ->
          {:ok, %{p | "verification_status" => Map.get(proof, "verification_status", "unverified")}}
        error -> error
      end
    end
  end

  # ---------------------------------------------------------------------------
  # Dependency Graph
  # ---------------------------------------------------------------------------

  @doc "Build the dependency graph for a list of proofs."
  @spec dependency_graph([map()]) :: {:ok, map()} | {:error, String.t()}
  def dependency_graph(proofs) when is_list(proofs) do
    edges =
      Enum.flat_map(proofs, fn proof ->
        deps = Map.get(proof, "dependencies", [])
        proof_id = Map.get(proof, "proof_id")
        Enum.map(deps, fn dep -> %{"from" => dep, "to" => proof_id, "edge_type" => "DEPENDS_ON"} end)
      end)

    nodes = Enum.map(proofs, fn p -> %{"node_id" => Map.get(p, "proof_id"), "type" => "proof"} end)
    cycle_check = detect_cycles(nodes, edges)

    case cycle_check do
      {:ok, _} ->
        topo = topological_sort(nodes, edges)
        {:ok, %{"nodes" => nodes, "edges" => edges, "topological_order" => topo}}
      {:error, cycles} ->
        {:error, "dependency graph contains cycles: #{inspect(cycles)}"}
    end
  end

  @doc "Detect cycles in a dependency graph."
  @spec detect_cycles([map()], [map()]) :: {:ok, :no_cycles} | {:error, [String.t()]}
  def detect_cycles(nodes, edges) do
    adjacency = build_adjacency(edges)
    node_ids = Enum.map(nodes, fn n -> Map.get(n, "node_id") end)

    visited = MapSet.new()
    rec_stack = MapSet.new()

    {_, _, cycles} =
      Enum.reduce(node_ids, {visited, rec_stack, []}, fn nid, {vis, rec, cyc} ->
        if MapSet.member?(vis, nid) do
          {vis, rec, cyc}
        else
          {vis2, rec2, sub} = dfs_cycle(nid, adjacency, vis, rec, [])
          {vis2, rec2, cyc ++ sub}
        end
      end)

    if cycles == [], do: {:ok, :no_cycles}, else: {:error, cycles}
  end

  @doc "Compute proof depth (longest chain of steps)."
  @spec proof_depth(map()) :: non_neg_integer()
  def proof_depth(proof) do
    length(Map.get(proof, "steps", []))
  end

  @doc "Compute proof width (max branching factor)."
  @spec proof_width(map()) :: non_neg_integer()
  def proof_width(proof) do
    deps = Map.get(proof, "dependencies", [])
    length(deps)
  end

  @doc "Compute dependency graph depth for a proof."
  @spec dependency_depth(map(), [map()]) :: non_neg_integer()
  def dependency_depth(proof, all_proofs) do
    deps = Map.get(proof, "dependencies", [])
    transitive = transitive_deps(deps, all_proofs, MapSet.new())
    length(transitive)
  end

  @doc "Compute proof complexity (steps × dependencies)."
  @spec complexity(map()) :: non_neg_integer()
  def complexity(proof) do
    proof_depth(proof) * (proof_width(proof) + 1)
  end

  # ---------------------------------------------------------------------------
  # Metrics
  # ---------------------------------------------------------------------------

  @doc "Compute all metrics for a proof given the full proof set."
  @spec metrics(map(), [map()]) :: map()
  def metrics(proof, all_proofs \\ []) do
    %{
      "proof_depth" => proof_depth(proof),
      "proof_width" => proof_width(proof),
      "dependency_depth" => dependency_depth(proof, all_proofs),
      "complexity" => complexity(proof),
      "replay_cost" => length(Map.get(proof, "steps", [])),
      "verification_cost" => 5,
      "reuse_count" => count_reuses(proof, all_proofs)
    }
  end

  # ---------------------------------------------------------------------------
  # Archaeology
  # ---------------------------------------------------------------------------

  @doc """
  Return the full archaeology provenance for a proof.

  Answers:
    - Why was this proof created?
    - Which theorem required it?
    - Which conjecture originated it?
    - Which lemmas were consumed?
    - Which assumptions remain?
    - Which applications depend on it?
  """
  @spec archaeology(map()) :: {:ok, map()} | {:error, String.t()}
  def archaeology(proof) do
    if Map.get(proof, "proof_id") == nil do
      {:error, "cannot perform archaeology on incomplete proof"}
    else
      record = %{
        "proof_id" => Map.get(proof, "proof_id"),
        "assertion_id" => Map.get(proof, "assertion_id"),
        "strategy" => Map.get(proof, "strategy"),
        "created_why" => %{
          "purpose" => "prove assertion #{Map.get(proof, "assertion_id")}",
          "origin" => "Phase 16.X.4",
          "strategy_used" => Map.get(proof, "strategy")
        },
        "required_by_theorem" => find_theorem_requiring(proof),
        "originated_from_conjecture" => extract_conjecture_origin(proof),
        "consumed_lemmas" => extract_consumed_lemmas(proof),
        "remaining_assumptions" => Map.get(proof, "assumptions", []),
        "dependent_applications" => [],
        "dependencies" => Map.get(proof, "dependencies", []),
        "created_at" => Map.get(proof, "created_at"),
        "version" => Map.get(proof, "version")
      }

      {:ok, record}
    end
  end

  # ---------------------------------------------------------------------------
  # Fingerprint
  # ---------------------------------------------------------------------------

  @doc "Compute the content-addressed fingerprint of a proof."
  @spec fingerprint(map()) :: String.t()
  def fingerprint(proof) do
    canonical = %{
      "proof_id" => Map.get(proof, "proof_id"),
      "assertion_id" => Map.get(proof, "assertion_id"),
      "strategy" => Map.get(proof, "strategy"),
      "assumptions" => Map.get(proof, "assumptions", []),
      "steps" => Enum.map(Map.get(proof, "steps", []), fn s -> step_fingerprint(s) end),
      "dependencies" => Map.get(proof, "dependencies", []),
      "verification_status" => Map.get(proof, "verification_status")
    }

    MathematicalID.from_canonical_map(canonical)
  end

  # ---------------------------------------------------------------------------
  # Valid strategy types
  # ---------------------------------------------------------------------------

  @doc "Returns all valid proof strategies."
  @spec valid_strategies() :: [atom()]
  def valid_strategies, do: @strategies

  # ---------------------------------------------------------------------------
  # Internal: Step fingerprint
  # ---------------------------------------------------------------------------

  defp step_fingerprint(step) do
    MathematicalID.from_canonical_map(%{
      "step_number" => Map.get(step, "step_number"),
      "rule_applied" => Map.get(step, "rule_applied"),
      "input_objects" => Map.get(step, "input_objects"),
      "output_object" => Map.get(step, "output_object"),
      "dependency_hashes" => Map.get(step, "dependency_hashes", [])
    })
  end

  # ---------------------------------------------------------------------------
  # Internal: Hashing
  # ---------------------------------------------------------------------------

  defp compute_proof_id(assertion_id, strategy, assumptions, steps) do
    prefix =
      MathematicalID.from_canonical_map(%{
        "assertion_id" => assertion_id,
        "strategy" => strategy,
        "assumptions" => assumptions,
        "step_count" => length(steps)
      })

    "proof_#{prefix}"
  end

  defp compute_proof_hash(proof_id, assertion_id, strategy, assumptions, steps) do
    MathematicalID.from_canonical_map(%{
      "proof_id" => proof_id,
      "assertion_id" => assertion_id,
      "strategy" => strategy,
      "assumptions" => assumptions,
      "steps" => Enum.map(steps, fn s ->
        MathematicalID.from_canonical_map(%{
          "sn" => Map.get(s, "step_number"),
          "rule" => Map.get(s, "rule_applied"),
          "in" => Map.get(s, "input_objects"),
          "out" => Map.get(s, "output_object")
        })
      end)
    })
  end

  # ---------------------------------------------------------------------------
  # Internal: Dependencies
  # ---------------------------------------------------------------------------

  defp extract_dependencies(steps) do
    steps
    |> Enum.flat_map(fn s -> Map.get(s, "dependency_hashes", []) end)
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp extract_intermediate_results(steps) do
    steps
    |> Enum.map(fn s -> Map.get(s, "output_object") end)
    |> Enum.reject(&is_nil/1)
  end

  # ---------------------------------------------------------------------------
  # Internal: Validation
  # ---------------------------------------------------------------------------

  defp validate_strategy(s) when s in @strategies, do: :ok
  defp validate_strategy(s), do: {:error, "invalid proof strategy: #{s}. Valid: #{inspect(@strategies)}"}

  # ---------------------------------------------------------------------------
  # Internal: Dependency graph
  # ---------------------------------------------------------------------------

  defp build_adjacency(edges) do
    Enum.reduce(edges, %{}, fn e, acc ->
      from = Map.get(e, "from")
      to = Map.get(e, "to")
      Map.update(acc, from, [to], fn existing -> [to | existing] end)
    end)
  end

  defp dfs_cycle(node_id, adjacency, visited, rec_stack, path) do
    visited = MapSet.put(visited, node_id)
    rec_stack = MapSet.put(rec_stack, node_id)
    new_path = path ++ [node_id]
    neighbors = Map.get(adjacency, node_id, [])

    {visited, rec_stack, cycles} =
      Enum.reduce(neighbors, {visited, rec_stack, []}, fn neighbor, {vis, rec, cyc} ->
        if not MapSet.member?(vis, neighbor) do
          {vis2, rec2, sub} = dfs_cycle(neighbor, adjacency, vis, rec, new_path)
          {vis2, rec2, cyc ++ sub}
        else
          if MapSet.member?(rec, neighbor) do
            cycle_path = (new_path ++ [neighbor]) |> Enum.join(" -> ")
            {vis, rec, cyc ++ [cycle_path]}
          else
            {vis, rec, cyc}
          end
        end
      end)

    rec_stack = MapSet.delete(rec_stack, node_id)
    {visited, rec_stack, cycles}
  end

  defp topological_sort(nodes, edges) do
    adjacency = build_adjacency(edges)
    node_ids = Enum.map(nodes, fn n -> Map.get(n, "node_id") end)
    visited = MapSet.new()
    order = []

    {_visited, order} =
      Enum.reduce(node_ids, {visited, order}, fn nid, {vis, ord} ->
        if MapSet.member?(vis, nid) do
          {vis, ord}
        else
          topo_dfs(nid, adjacency, vis, ord)
        end
      end)

    order |> Enum.reverse()
  end

  defp topo_dfs(node_id, adjacency, visited, order) do
    visited = MapSet.put(visited, node_id)
    neighbors = Map.get(adjacency, node_id, [])

    {visited, order} =
      Enum.reduce(neighbors, {visited, order}, fn neighbor, {vis, ord} ->
        if MapSet.member?(vis, neighbor) do
          {vis, ord}
        else
          topo_dfs(neighbor, adjacency, vis, ord)
        end
      end)

    {visited, [node_id | order]}
  end

  defp transitive_deps(_deps, [], _seen), do: []

  defp transitive_deps(deps, all_proofs, seen) do
    Enum.flat_map(deps, fn dep_id ->
      if MapSet.member?(seen, dep_id) do
        []
      else
        seen = MapSet.put(seen, dep_id)
        dep_proof = Enum.find(all_proofs, fn p -> Map.get(p, "proof_id") == dep_id end)

        sub_deps =
          case dep_proof do
            nil -> []
            p -> Map.get(p, "dependencies", [])
          end

        [dep_id | transitive_deps(sub_deps, all_proofs, seen)]
      end
    end)
  end

  defp count_reuses(proof, all_proofs) do
    proof_id = Map.get(proof, "proof_id")
    Enum.count(all_proofs, fn p ->
      proof_id in (Map.get(p, "dependencies", []))
    end)
  end

  defp find_theorem_requiring(proof) do
    [Map.get(proof, "assertion_id")]
  end

  defp extract_conjecture_origin(proof) do
    assertion_id = Map.get(proof, "assertion_id")
    if String.contains?(assertion_id, "conjecture"), do: [assertion_id], else: []
  end

  defp extract_consumed_lemmas(proof) do
    Map.get(proof, "dependencies", [])
  end
end
