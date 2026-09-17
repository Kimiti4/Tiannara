defmodule TiannaraRuntime.Mathematics.Ontology.Axiom do
  @moduledoc "Phase 16.X.1 — Axiom: fundamental, unproven starting point."
  @enforce_keys [:statement]
  defstruct [:id, :statement, :axiom_set_id, :status, :metadata]
  @type t :: %__MODULE__{id: String.t() | nil, statement: String.t(), axiom_set_id: String.t() | nil, status: atom() | nil, metadata: map()}
  @spec new(String.t(), keyword()) :: {:ok, t()} | {:error, String.t()}
  def new(statement, opts \\ []) when is_binary(statement) do
    axiom = %__MODULE__{id: nil, statement: statement, axiom_set_id: Keyword.get(opts, :axiom_set_id), status: Keyword.get(opts, :status, :active), metadata: Keyword.get(opts, :metadata, %{})}
    validate(axiom)
  end
  @spec validate(t()) :: {:ok, t()} | {:error, String.t()}
  def validate(%__MODULE__{statement: s}) when byte_size(s) == 0, do: {:error, "statement must not be empty"}
  def validate(%__MODULE__{} = a), do: {:ok, a}
  def validate(_), do: {:error, "invalid"}
  @spec id(t()) :: String.t()
  def id(%__MODULE__{} = a), do: TiannaraRuntime.Mathematics.MathematicalID.from_canonical_map(%{"statement" => a.statement, "axiom_set_id" => a.axiom_set_id, "status" => a.status})
end

defmodule TiannaraRuntime.Mathematics.Ontology.Definition do
  @moduledoc "Phase 16.X.1 — Definition: precise concept specification."
  @enforce_keys [:name, :formal_statement]
  defstruct [:id, :name, :formal_statement, :dependencies, :examples, :introduced_in, :metadata]
  @type t :: %__MODULE__{id: String.t() | nil, name: String.t(), formal_statement: String.t(), dependencies: [String.t()], examples: [String.t()], introduced_in: String.t() | nil, metadata: map()}
  @spec new(String.t(), String.t(), keyword()) :: {:ok, t()} | {:error, String.t()}
  def new(name, formal_statement, opts \\ []) when is_binary(name) and is_binary(formal_statement) do
    d = %__MODULE__{id: nil, name: name, formal_statement: formal_statement, dependencies: Keyword.get(opts, :dependencies, []), examples: Keyword.get(opts, :examples, []), introduced_in: Keyword.get(opts, :introduced_in), metadata: Keyword.get(opts, :metadata, %{})}
    validate(d)
  end
  @spec validate(t()) :: {:ok, t()} | {:error, String.t()}
  def validate(%__MODULE__{name: n, formal_statement: fs}) when byte_size(n) == 0 or byte_size(fs) == 0, do: {:error, "name and formal_statement must not be empty"}
  def validate(%__MODULE__{} = d), do: {:ok, d}
  def validate(_), do: {:error, "invalid"}
end

defmodule TiannaraRuntime.Mathematics.Ontology.Structure do
  @moduledoc "Phase 16.X.1 — Structure: set with operations satisfying axioms."
  @enforce_keys [:name]
  defstruct [:id, :name, :operations, :axiom_refs, :substructures, :metadata]
  @type t :: %__MODULE__{id: String.t() | nil, name: String.t(), operations: [String.t()], axiom_refs: [String.t()], substructures: [String.t()], metadata: map()}
  @spec new(String.t(), keyword()) :: {:ok, t()} | {:error, String.t()}
  def new(name, opts \\ []) when is_binary(name) do
    s = %__MODULE__{id: nil, name: name, operations: Keyword.get(opts, :operations, []), axiom_refs: Keyword.get(opts, :axiom_refs, []), substructures: Keyword.get(opts, :substructures, []), metadata: Keyword.get(opts, :metadata, %{})}
    validate(s)
  end
  @spec validate(t()) :: {:ok, t()} | {:error, String.t()}
  def validate(%__MODULE__{name: n}) when byte_size(n) == 0, do: {:error, "name must not be empty"}
  def validate(%__MODULE__{} = s), do: {:ok, s}
  def validate(_), do: {:error, "invalid"}
end

defmodule TiannaraRuntime.Mathematics.Ontology.Conjecture do
  @moduledoc "Phase 16.X.1 — Conjecture: unproven statement."
  @enforce_keys [:statement]
  defstruct [:id, :statement, :evidence, :confidence, :generating_context, :status, :metadata]
  @type t :: %__MODULE__{id: String.t() | nil, statement: String.t(), evidence: [String.t()], confidence: float(), generating_context: map(), status: atom() | nil, metadata: map()}
  @spec new(String.t(), keyword()) :: {:ok, t()} | {:error, String.t()}
  def new(statement, opts \\ []) when is_binary(statement) do
    c = %__MODULE__{id: nil, statement: statement, evidence: Keyword.get(opts, :evidence, []), confidence: Keyword.get(opts, :confidence, 0.0), generating_context: Keyword.get(opts, :generating_context, %{}), status: Keyword.get(opts, :status, :open), metadata: Keyword.get(opts, :metadata, %{})}
    validate(c)
  end
  @spec validate(t()) :: {:ok, t()} | {:error, String.t()}
  def validate(%__MODULE__{statement: s}) when byte_size(s) == 0, do: {:error, "statement must not be empty"}
  def validate(%__MODULE__{confidence: c}) when not is_number(c) or c < 0.0 or c > 1.0, do: {:error, "confidence must be in [0.0, 1.0]"}
  def validate(%__MODULE__{} = c), do: {:ok, c}
  def validate(_), do: {:error, "invalid"}
  @spec id(t()) :: String.t()
  def id(%__MODULE__{} = c), do: TiannaraRuntime.Mathematics.MathematicalID.from_canonical_map(%{"statement" => c.statement, "generating_context" => c.generating_context})
end

defmodule TiannaraRuntime.Mathematics.Ontology.Lemma do
  @moduledoc "Phase 16.X.1 — Lemma: helper theorem used in proofs."
  @enforce_keys [:statement, :proof_hash]
  defstruct [:id, :statement, :proof_hash, :dependencies, :metadata]
  @type t :: %__MODULE__{id: String.t() | nil, statement: String.t(), proof_hash: String.t(), dependencies: [String.t()], metadata: map()}
  @spec new(String.t(), String.t(), keyword()) :: {:ok, t()} | {:error, String.t()}
  def new(statement, proof_hash, opts \\ []) when is_binary(statement) and is_binary(proof_hash) do
    l = %__MODULE__{id: nil, statement: statement, proof_hash: proof_hash, dependencies: Keyword.get(opts, :dependencies, []), metadata: Keyword.get(opts, :metadata, %{})}
    validate(l)
  end
  @spec validate(t()) :: {:ok, t()} | {:error, String.t()}
  def validate(%__MODULE__{statement: s, proof_hash: ph}) when byte_size(s) == 0 or byte_size(ph) == 0, do: {:error, "statement and proof_hash must not be empty"}
  def validate(%__MODULE__{} = l), do: {:ok, l}
  def validate(_), do: {:error, "invalid"}
end

defmodule TiannaraRuntime.Mathematics.Ontology.Theorem do
  @moduledoc "Phase 16.X.1 — Theorem: proven statement."
  @enforce_keys [:statement, :proof_hash]
  defstruct [:id, :statement, :proof_hash, :dependencies, :first_proven, :applications, :metadata]
  @type t :: %__MODULE__{id: String.t() | nil, statement: String.t(), proof_hash: String.t(), dependencies: [String.t()], first_proven: String.t() | nil, applications: [String.t()], metadata: map()}
  @spec new(String.t(), String.t(), keyword()) :: {:ok, t()} | {:error, String.t()}
  def new(statement, proof_hash, opts \\ []) when is_binary(statement) and is_binary(proof_hash) do
    t = %__MODULE__{id: nil, statement: statement, proof_hash: proof_hash, dependencies: Keyword.get(opts, :dependencies, []), first_proven: Keyword.get(opts, :first_proven), applications: Keyword.get(opts, :applications, []), metadata: Keyword.get(opts, :metadata, %{})}
    validate(t)
  end
  @spec validate(t()) :: {:ok, t()} | {:error, String.t()}
  def validate(%__MODULE__{statement: s, proof_hash: ph}) when byte_size(s) == 0 or byte_size(ph) == 0, do: {:error, "statement and proof_hash must not be empty"}
  def validate(%__MODULE__{} = t), do: {:ok, t}
  def validate(_), do: {:error, "invalid"}
  @spec id(t()) :: String.t()
  def id(%__MODULE__{} = t), do: TiannaraRuntime.Mathematics.MathematicalID.from_canonical_map(%{"statement" => t.statement, "proof_hash" => t.proof_hash, "dependencies" => t.dependencies})
end

defmodule TiannaraRuntime.Mathematics.Ontology.Proof do
  @moduledoc "Phase 16.X.1 — Proof: rigorous demonstration of truth."
  @enforce_keys [:conjecture_id, :strategy]
  defstruct [:id, :conjecture_id, :strategy, :premises, :steps, :conclusion, :verified, :metadata]
  @type proof_strategy :: :direct | :contradiction | :induction | :constructive | :computational
  @type t :: %__MODULE__{id: String.t() | nil, conjecture_id: String.t(), strategy: proof_strategy(), premises: [String.t()], steps: [map()], conclusion: String.t() | nil, verified: boolean(), metadata: map()}
  @spec new(String.t(), atom(), keyword()) :: {:ok, t()} | {:error, String.t()}
  def new(conjecture_id, strategy, opts \\ []) when is_binary(conjecture_id) do
    p = %__MODULE__{id: nil, conjecture_id: conjecture_id, strategy: strategy, premises: Keyword.get(opts, :premises, []), steps: Keyword.get(opts, :steps, []), conclusion: Keyword.get(opts, :conclusion), verified: Keyword.get(opts, :verified, false), metadata: Keyword.get(opts, :metadata, %{})}
    validate(p)
  end
  @spec validate(t()) :: {:ok, t()} | {:error, String.t()}
  def validate(%__MODULE__{conjecture_id: cid}) when byte_size(cid) == 0, do: {:error, "conjecture_id must not be empty"}
  def validate(%__MODULE__{} = p), do: {:ok, p}
  def validate(_), do: {:error, "invalid"}
end

defmodule TiannaraRuntime.Mathematics.Ontology.Corollary do
  @moduledoc "Phase 16.X.1 — Corollary: immediate consequence of a theorem."
  @enforce_keys [:statement, :parent_theorem_id]
  defstruct [:id, :statement, :parent_theorem_id, :metadata]
  @type t :: %__MODULE__{id: String.t() | nil, statement: String.t(), parent_theorem_id: String.t(), metadata: map()}
  @spec new(String.t(), String.t(), keyword()) :: {:ok, t()} | {:error, String.t()}
  def new(statement, parent_theorem_id, opts \\ []) when is_binary(statement) and is_binary(parent_theorem_id) do
    c = %__MODULE__{id: nil, statement: statement, parent_theorem_id: parent_theorem_id, metadata: Keyword.get(opts, :metadata, %{})}
    validate(c)
  end
  @spec validate(t()) :: {:ok, t()} | {:error, String.t()}
  def validate(%__MODULE__{statement: s, parent_theorem_id: pt}) when byte_size(s) == 0 or byte_size(pt) == 0, do: {:error, "statement and parent_theorem_id must not be empty"}
  def validate(%__MODULE__{} = c), do: {:ok, c}
  def validate(_), do: {:error, "invalid"}
end

defmodule TiannaraRuntime.Mathematics.Ontology.Algorithm do
  @moduledoc "Phase 16.X.1 — Algorithm: step-by-step procedure derived from theorems."
  @enforce_keys [:name, :theorem_provenance]
  defstruct [:id, :name, :theorem_provenance, :complexity, :determinism_guarantee, :implementation_status, :metadata]
  @type t :: %__MODULE__{id: String.t() | nil, name: String.t(), theorem_provenance: String.t(), complexity: String.t() | nil, determinism_guarantee: boolean(), implementation_status: String.t() | nil, metadata: map()}
  @spec new(String.t(), String.t(), keyword()) :: {:ok, t()} | {:error, String.t()}
  def new(name, theorem_provenance, opts \\ []) when is_binary(name) and is_binary(theorem_provenance) do
    a = %__MODULE__{id: nil, name: name, theorem_provenance: theorem_provenance, complexity: Keyword.get(opts, :complexity), determinism_guarantee: Keyword.get(opts, :determinism_guarantee, true), implementation_status: Keyword.get(opts, :implementation_status), metadata: Keyword.get(opts, :metadata, %{})}
    validate(a)
  end
  @spec validate(t()) :: {:ok, t()} | {:error, String.t()}
  def validate(%__MODULE__{name: n, theorem_provenance: tp}) when byte_size(n) == 0 or byte_size(tp) == 0, do: {:error, "name and theorem_provenance must not be empty"}
  def validate(%__MODULE__{} = a), do: {:ok, a}
  def validate(_), do: {:error, "invalid"}
end

defmodule TiannaraRuntime.Mathematics.Ontology.Application do
  @moduledoc "Phase 16.X.1 — Application: real-world mapping from math to engineering/science/governance."
  @enforce_keys [:problem_domain, :math_result]
  defstruct [:id, :problem_domain, :math_result, :implementation_ref, :verification_status, :metadata]
  @type t :: %__MODULE__{id: String.t() | nil, problem_domain: String.t(), math_result: String.t(), implementation_ref: String.t() | nil, verification_status: String.t() | nil, metadata: map()}
  @spec new(String.t(), String.t(), keyword()) :: {:ok, t()} | {:error, String.t()}
  def new(problem_domain, math_result, opts \\ []) when is_binary(problem_domain) and is_binary(math_result) do
    a = %__MODULE__{id: nil, problem_domain: problem_domain, math_result: math_result, implementation_ref: Keyword.get(opts, :implementation_ref), verification_status: Keyword.get(opts, :verification_status), metadata: Keyword.get(opts, :metadata, %{})}
    validate(a)
  end
  @spec validate(t()) :: {:ok, t()} | {:error, String.t()}
  def validate(%__MODULE__{problem_domain: pd, math_result: mr}) when byte_size(pd) == 0 or byte_size(mr) == 0, do: {:error, "problem_domain and math_result must not be empty"}
  def validate(%__MODULE__{} = a), do: {:ok, a}
  def validate(_), do: {:error, "invalid"}
end
