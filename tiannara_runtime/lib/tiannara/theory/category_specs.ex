defmodule Tiannara.Theory.CategorySpecs do
  @moduledoc """
  Type-level specifications for category-theoretic substrate model.
  [Original Concept: Reality Algebra Type System]
  
  These specs enable compile-time verification of invariant-preserving
  compositions using Elixir's type system and Dialyzer.
  """

  defstruct [:state, :invariants, :provenance]

  @typedoc "Object in substrate category C"
  @type t :: %__MODULE__{
    state: map(),
    invariants: MapSet.t(atom()),
    provenance: [atom()] # Subsystem history
  }

  @typedoc "Morphism in C: validated state transition"
  @type morphism :: %{
    from: t(),
    to: t(),
    proof: invariant_proof(),
    metadata: map()
  }

  @typedoc "Proof that invariants are preserved"
  @type invariant_proof :: %{
    causal_conservation: boolean(),
    observer_safety: boolean(),
    stability_bound: boolean(),
    semantic_coherence: boolean()
  }

  @typedoc "Functor representing a subsystem (OMCE, OLEF, RRG)"
  @type subsystem_functor :: %{
    name: atom(),
    map_object: (t() -> t()),
    map_morphism: (morphism() -> morphism()),
    preserves_invariants: MapSet.t(atom())
  }

  @typedoc "Natural transformation between functors"
  @type natural_transformation :: %{
    source: subsystem_functor(),
    target: subsystem_functor(),
    component: (t() -> morphism()),
    naturality_proof: boolean()
  }

  @spec compose_morphisms(m1 :: morphism(), m2 :: morphism()) :: {:ok, morphism()} | {:error, String.t()}
  def compose_morphisms(%{to: mid} = m1, %{from: mid} = m2) do
    # Verify codomain of m1 matches domain of m2
    combined_proof = merge_proofs(m1.proof, m2.proof)
    
    if Enum.all?(Map.values(combined_proof), & &1) do
      {:ok, %{
        from: m1.from,
        to: m2.to,
        proof: combined_proof,
        metadata: Map.merge(m1.metadata, m2.metadata)
      }}
    else
      {:error, "Invariant proof failed in composition"}
    end
  end

  def compose_morphisms(_, _), do: {:error, "Morphisms not composable: domain/codomain mismatch"}

  defp merge_proofs(p1, p2) do
    Map.new(p1, fn {k, v} -> {k, v and Map.get(p2, k, false)} end)
  end
end