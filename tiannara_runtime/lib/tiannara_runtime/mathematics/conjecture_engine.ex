defmodule TiannaraRuntime.Mathematics.ConjectureEngine do
  @moduledoc """
  Phase 16.X.5 — Constitutional Conjecture Engine

  Generates mathematically interesting research candidates.

  Every conjecture is a hypothesis. No conjecture is truth.
  Truth requires proof.

  The engine does NOT prove conjectures, certify them, or automatically
  promote them to theorems. Conjectures become research objects only.

  Sources: Knowledge Gaps, Repeated Structures, Incomplete Proofs,
  Pattern Detection, Generalization, Specialization, Symmetry,
  Counterexamples, Human Input.
  """

  @sources ~w(knowledge_gap repeated_structure incomplete_proof pattern generalization specialization symmetry counterexample human_input)

  @clusters ~w(algebra topology tensors optimization graph_theory information_theory category_theory probability)

  alias TiannaraRuntime.Mathematics.MathematicalID

  # ---------------------------------------------------------------------------
  # Conjecture Generation
  # ---------------------------------------------------------------------------

  @doc "Generate a conjecture from a source with given parameters."
  @spec generate_conjecture(String.t(), map()) :: {:ok, map()} | {:error, String.t()}
  def generate_conjecture(statement, opts \\ %{}) when is_binary(statement) do
    source = Map.get(opts, "source", "knowledge_gap")
    generator = Map.get(opts, "generator", "Phase 16.X.5")

    with :ok <- validate_source(source) do
      now = :erlang.unique_integer([:positive]) |> Integer.to_string()

      priority = compute_priority(statement, opts)
      cluster = assign_cluster(statement, opts)

      conjecture = %{
        "conjecture_id" => compute_conjecture_id(statement, source),
        "statement" => statement,
        "origin" => source,
        "generator" => generator,
        "priority" => priority,
        "dependencies" => Map.get(opts, "dependencies", []),
        "related_structures" => Map.get(opts, "related_structures", []),
        "research_value" => Map.get(opts, "research_value", 0.5),
        "uncertainty" => Map.get(opts, "uncertainty", 1.0),
        "complexity" => Map.get(opts, "complexity", 1),
        "cluster" => cluster,
        "status" => "candidate",
        "created_at" => now,
        "version" => "1.0.0"
      }

      {:ok, conjecture}
    end
  end

  @doc "Generate from a knowledge gap."
  @spec from_knowledge_gap(String.t(), map()) :: {:ok, map()} | {:error, String.t()}
  def from_knowledge_gap(statement, opts \\ %{}) do
    generate_conjecture(statement, Map.merge(opts, %{"source" => "knowledge_gap"}))
  end

  @doc "Generate from a repeated structure."
  @spec from_repeated_structure(String.t(), map()) :: {:ok, map()} | {:error, String.t()}
  def from_repeated_structure(statement, opts \\ %{}) do
    generate_conjecture(statement, Map.merge(opts, %{"source" => "repeated_structure"}))
  end

  @doc "Generate from an incomplete proof."
  @spec from_incomplete_proof(String.t(), map()) :: {:ok, map()} | {:error, String.t()}
  def from_incomplete_proof(statement, opts \\ %{}) do
    generate_conjecture(statement, Map.merge(opts, %{"source" => "incomplete_proof"}))
  end

  @doc "Generate from pattern detection."
  @spec from_pattern(String.t(), map()) :: {:ok, map()} | {:error, String.t()}
  def from_pattern(statement, opts \\ %{}) do
    generate_conjecture(statement, Map.merge(opts, %{"source" => "pattern"}))
  end

  @doc "Generate from generalization of an existing result."
  @spec from_generalization(String.t(), map()) :: {:ok, map()} | {:error, String.t()}
  def from_generalization(statement, opts \\ %{}) do
    generate_conjecture(statement, Map.merge(opts, %{"source" => "generalization"}))
  end

  @doc "Generate from specialization of an existing result."
  @spec from_specialization(String.t(), map()) :: {:ok, map()} | {:error, String.t()}
  def from_specialization(statement, opts \\ %{}) do
    generate_conjecture(statement, Map.merge(opts, %{"source" => "specialization"}))
  end

  @doc "Generate from symmetry observation."
  @spec from_symmetry(String.t(), map()) :: {:ok, map()} | {:error, String.t()}
  def from_symmetry(statement, opts \\ %{}) do
    generate_conjecture(statement, Map.merge(opts, %{"source" => "symmetry"}))
  end

  @doc "Generate from a counterexample."
  @spec from_counterexample(String.t(), map()) :: {:ok, map()} | {:error, String.t()}
  def from_counterexample(statement, opts \\ %{}) do
    generate_conjecture(statement, Map.merge(opts, %{"source" => "counterexample"}))
  end

  @doc "Generate from human input."
  @spec from_human_input(String.t(), map()) :: {:ok, map()} | {:error, String.t()}
  def from_human_input(statement, opts \\ %{}) do
    generate_conjecture(statement, Map.merge(opts, %{"source" => "human_input"}))
  end

  # ---------------------------------------------------------------------------
  # Validation
  # ---------------------------------------------------------------------------

  @doc "Validate a conjecture: check all required fields are present."
  @spec validate_conjecture(map()) :: {:ok, map()} | {:error, String.t()}
  def validate_conjecture(conjecture) do
    required = ~w(conjecture_id statement origin priority status created_at)
    missing = Enum.reject(required, fn k -> Map.has_key?(conjecture, k) and Map.get(conjecture, k) != nil end)

    if missing == [] do
      source = Map.get(conjecture, "origin", "")
      case validate_source(source) do
        :ok -> {:ok, conjecture}
        error -> error
      end
    else
      {:error, "conjecture validation failed: missing fields: #{Enum.join(missing, ", ")}"}
    end
  end

  # ---------------------------------------------------------------------------
  # Lifecycle transitions
  # ---------------------------------------------------------------------------

  @doc "Transition a conjecture through its lifecycle."
  @spec transition(map(), String.t()) :: {:ok, map()} | {:error, String.t()}
  def transition(conjecture, new_status) do
    current = Map.get(conjecture, "status", "")

    valid = valid_transition?(current, new_status)

    case valid do
      :ok ->
        {:ok, Map.put(conjecture, "status", new_status)}
      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc "Register a conjecture into the research queue (promote from candidate)."
  @spec register_conjecture(map()) :: {:ok, map()} | {:error, String.t()}
  def register_conjecture(conjecture) do
    transition(conjecture, "registered")
  end

  # ---------------------------------------------------------------------------
  # Priority Engine
  # ---------------------------------------------------------------------------

  @doc "Compute the deterministic priority score for a conjecture."
  @spec compute_priority(String.t(), map()) :: float()
  def compute_priority(statement, opts \\ %{}) do
    novelty = Map.get(opts, "novelty", 0.5)
    impact = Map.get(opts, "potential_impact", 0.5)
    dep_count = Map.get(opts, "dependencies", []) |> length()
    difficulty = Map.get(opts, "proof_difficulty", 0.5)
    sci_value = Map.get(opts, "scientific_value", 0.5)
    eng_value = Map.get(opts, "engineering_value", 0.5)
    reuse = Map.get(opts, "reuse_potential", 0.5)

    score =
      0.25 * novelty +
        0.20 * impact +
        0.10 * (1.0 - min(dep_count / 20, 1.0)) +
        0.15 * (1.0 - difficulty) +
        0.10 * sci_value +
        0.10 * eng_value +
        0.10 * reuse

    Float.round(score, 4)
  end

  # ---------------------------------------------------------------------------
  # Clustering
  # ---------------------------------------------------------------------------

  @doc "Assign a conjecture to a mathematical cluster based on its statement."
  @spec assign_cluster(String.t(), map()) :: String.t()
  def assign_cluster(statement, opts \\ %{}) do
    hint = Map.get(opts, "cluster_hint", "")
    if hint != "" and hint in @clusters do
      hint
    else
      detect_cluster(statement)
    end
  end

  @doc "Group a list of conjectures by their assigned cluster."
  @spec cluster_by_domain([map()]) :: {:ok, map()}
  def cluster_by_domain(conjectures) do
    grouped =
      Enum.group_by(conjectures, fn c -> Map.get(c, "cluster", "unassigned") end)
      |> Enum.map(fn {cluster, items} ->
        {cluster, Enum.sort_by(items, fn c -> Map.get(c, "conjecture_id") end)}
      end)
      |> Map.new()

    {:ok, grouped}
  end

  @doc "Returns all valid clusters."
  @spec valid_clusters() :: [String.t()]
  def valid_clusters, do: @clusters

  @doc "Returns all valid sources."
  @spec valid_sources() :: [String.t()]
  def valid_sources, do: @sources

  # ---------------------------------------------------------------------------
  # Replay
  # ---------------------------------------------------------------------------

  @doc """
  Replay conjecture generation from its stored data.

  Uses only: graph, ontology, deterministic context.
  Produces identical conjectures, priorities, clusters, and research queue.
  """
  @spec replay_conjecture(map()) :: {:ok, map()} | {:error, String.t()}
  def replay_conjecture(conjecture) do
    statement = Map.get(conjecture, "statement")
    source = Map.get(conjecture, "origin", "knowledge_gap")
    opts = %{
      "source" => source,
      "generator" => Map.get(conjecture, "generator", "Phase 16.X.5"),
      "dependencies" => Map.get(conjecture, "dependencies", []),
      "related_structures" => Map.get(conjecture, "related_structures", []),
      "research_value" => Map.get(conjecture, "research_value", 0.5),
      "uncertainty" => Map.get(conjecture, "uncertainty", 1.0),
      "complexity" => Map.get(conjecture, "complexity", 1),
      "cluster_hint" => Map.get(conjecture, "cluster")
    }

    case generate_conjecture(statement, opts) do
      {:ok, replayed} ->
        {:ok, %{replayed | "status" => Map.get(conjecture, "status", "candidate")}}
      error -> error
    end
  end

  @doc "Replay the research queue ordering from a list of conjectures."
  @spec replay_research_queue([map()]) :: {:ok, [map()]}
  def replay_research_queue(conjectures) do
    sorted =
      conjectures
      |> Enum.sort_by(fn c ->
        {-Map.get(c, "priority", 0.0), Map.get(c, "conjecture_id")}
      end)

    {:ok, sorted}
  end

  # ---------------------------------------------------------------------------
  # Archaeology
  # ---------------------------------------------------------------------------

  @doc """
  Return the full archaeology provenance for a conjecture.

  Answers:
    - Why was this conjecture generated?
    - Which knowledge gap?
    - Which patterns?
    - Which structures?
    - Which later proofs?
    - Which applications?
  """
  @spec archaeology(map()) :: {:ok, map()} | {:error, String.t()}
  def archaeology(conjecture) do
    if Map.get(conjecture, "conjecture_id") == nil do
      {:error, "cannot perform archaeology on incomplete conjecture"}
    else
      record = %{
        "conjecture_id" => Map.get(conjecture, "conjecture_id"),
        "statement" => Map.get(conjecture, "statement"),
        "generated_why" => %{
          "origin" => Map.get(conjecture, "origin"),
          "generator" => Map.get(conjecture, "generator"),
          "reason" => source_description(Map.get(conjecture, "origin"))
        },
        "knowledge_gap" => Map.get(conjecture, "dependencies", []),
        "detected_patterns" => [],
        "related_structures" => Map.get(conjecture, "related_structures", []),
        "produced_proofs" => [],
        "applications" => [],
        "cluster" => Map.get(conjecture, "cluster"),
        "created_at" => Map.get(conjecture, "created_at"),
        "version" => Map.get(conjecture, "version")
      }

      {:ok, record}
    end
  end

  # ---------------------------------------------------------------------------
  # Metrics
  # ---------------------------------------------------------------------------

  @doc "Compute aggregate metrics for a set of conjectures."
  @spec metrics([map()]) :: map()
  def metrics(conjectures) do
    total = length(conjectures)
    resolved = Enum.count(conjectures, fn c -> Map.get(c, "status") == "archived" end)
    registered = Enum.count(conjectures, fn c -> Map.get(c, "status") == "registered" end)
    candidates = Enum.count(conjectures, fn c -> Map.get(c, "status") == "candidate" end)

    priorities = Enum.map(conjectures, fn c -> Map.get(c, "priority", 0.0) end)
    avg_priority = if total > 0, do: Enum.sum(priorities) / total, else: 0.0

    clusters = Enum.map(conjectures, fn c -> Map.get(c, "cluster", "unassigned") end)
    unique_clusters = Enum.uniq(clusters) |> length()

    avg_uncertainty =
      if total > 0 do
        uncertainties = Enum.map(conjectures, fn c -> Map.get(c, "uncertainty", 1.0) end)
        Enum.sum(uncertainties) / total
      else
        0.0
      end

    %{
      "conjecture_count" => total,
      "resolution_rate" => if(total > 0, do: Float.round(resolved / total, 4), else: 0.0),
      "registered_count" => registered,
      "candidate_count" => candidates,
      "average_priority" => Float.round(avg_priority, 4),
      "cluster_diversity" => unique_clusters,
      "average_uncertainty" => Float.round(avg_uncertainty, 4)
    }
  end

  # ---------------------------------------------------------------------------
  # Research Queue
  # ---------------------------------------------------------------------------

  @doc "Build the research queue: conjectures sorted by priority (descending)."
  @spec research_queue([map()]) :: {:ok, [map()]}
  def research_queue(conjectures) do
    replay_research_queue(conjectures)
  end

  # ---------------------------------------------------------------------------
  # Internal: Validation
  # ---------------------------------------------------------------------------

  defp validate_source(src) when src in @sources, do: :ok
  defp validate_source(src), do: {:error, "invalid conjecture source: #{src}. Valid: #{inspect(@sources)}"}

  defp valid_transition?("candidate", "validated"), do: :ok
  defp valid_transition?("validated", "registered"), do: :ok
  defp valid_transition?("registered", "archived"), do: :ok
  defp valid_transition?("candidate", "archived"), do: :ok
  defp valid_transition?(current, _new), do: {:error, "invalid transition from #{current}"}

  # ---------------------------------------------------------------------------
  # Internal: Hashing
  # ---------------------------------------------------------------------------

  defp compute_conjecture_id(statement, source) do
    prefix =
      MathematicalID.from_canonical_map(%{
        "statement" => statement,
        "source" => source
      })

    "conjecture_#{prefix}"
  end

  # ---------------------------------------------------------------------------
  # Internal: Cluster detection
  # ---------------------------------------------------------------------------

  defp detect_cluster(statement) do
    lower = String.downcase(statement)

    cond do
      String.contains?(lower, "algebra") or String.contains?(lower, "group") or
        String.contains?(lower, "ring") or String.contains?(lower, "field") ->
        "algebra"

      String.contains?(lower, "topology") or String.contains?(lower, "manifold") or
        String.contains?(lower, "continuous") or String.contains?(lower, "compact") ->
        "topology"

      String.contains?(lower, "tensor") or String.contains?(lower, "tensor_product") ->
        "tensors"

      String.contains?(lower, "optimization") or String.contains?(lower, "minim") or
        String.contains?(lower, "maxim") or String.contains?(lower, "convex") ->
        "optimization"

      String.contains?(lower, "graph") or String.contains?(lower, "vertex") or
        String.contains?(lower, "edge") or String.contains?(lower, "network") ->
        "graph_theory"

      String.contains?(lower, "entropy") or String.contains?(lower, "information") or
        String.contains?(lower, "coding") or String.contains?(lower, "channel") ->
        "information_theory"

      String.contains?(lower, "category") or String.contains?(lower, "functor") or
        String.contains?(lower, "natural transformation") or String.contains?(lower, "morphism") ->
        "category_theory"

      String.contains?(lower, "probability") or String.contains?(lower, "random") or
        String.contains?(lower, "distribution") or String.contains?(lower, "stochastic") ->
        "probability"

      true ->
        "algebra"
    end
  end

  defp source_description("knowledge_gap"), do: "generated from identified knowledge gap"
  defp source_description("repeated_structure"), do: "generated from repeated structural pattern"
  defp source_description("incomplete_proof"), do: "generated from incomplete proof"
  defp source_description("pattern"), do: "generated from detected pattern"
  defp source_description("generalization"), do: "generated by generalizing existing result"
  defp source_description("specialization"), do: "generated by specializing existing result"
  defp source_description("symmetry"), do: "generated from symmetry observation"
  defp source_description("counterexample"), do: "generated from counterexample analysis"
  defp source_description("human_input"), do: "generated from human-provided input"
  defp source_description(_), do: "generated from unknown source"
end
