defmodule TiannaraRuntime.Mathematics.Ontology.ProofStep do
  @moduledoc "Phase 16.X.1 — ProofStep: single step in a proof."
  @enforce_keys [:step_number, :rule_applied, :conclusion]
  defstruct [:step_number, :rule_applied, :premises, :conclusion, :justification]
  @type t :: %__MODULE__{step_number: non_neg_integer(), rule_applied: String.t(), premises: [String.t()], conclusion: String.t(), justification: String.t() | nil}
  @spec new(non_neg_integer(), String.t(), String.t(), keyword()) :: {:ok, t()} | {:error, String.t()}
  def new(step_number, rule_applied, conclusion, opts \\ []) do
    ps = %__MODULE__{step_number: step_number, rule_applied: rule_applied, premises: Keyword.get(opts, :premises, []), conclusion: conclusion, justification: Keyword.get(opts, :justification)}
    validate(ps)
  end
  @spec validate(t()) :: {:ok, t()} | {:error, String.t()}
  def validate(%__MODULE__{step_number: sn}) when not is_integer(sn) or sn < 0, do: {:error, "step_number must be a non-negative integer"}
  def validate(%__MODULE__{rule_applied: ra}) when byte_size(ra) == 0, do: {:error, "rule_applied must not be empty"}
  def validate(%__MODULE__{conclusion: c}) when byte_size(c) == 0, do: {:error, "conclusion must not be empty"}
  def validate(%__MODULE__{} = ps), do: {:ok, ps}
  def validate(_), do: {:error, "invalid"}
  @spec id(t()) :: String.t()
  def id(%__MODULE__{} = ps), do: TiannaraRuntime.Mathematics.MathematicalID.from_canonical_map(%{"step_number" => ps.step_number, "rule_applied" => ps.rule_applied, "premises" => ps.premises, "conclusion" => ps.conclusion})
end

defmodule TiannaraRuntime.Mathematics.Ontology.ProofStrategy do
  @moduledoc "Phase 16.X.1 — ProofStrategy: type-only, one of :direct, :contradiction, :induction, :constructive, :computational."
  @type t :: :direct | :contradiction | :induction | :constructive | :computational
  @spec valid() :: [t()]
  def valid, do: [:direct, :contradiction, :induction, :constructive, :computational]
  @spec validate(atom()) :: {:ok, t()} | {:error, String.t()}
  def validate(strategy) when is_atom(strategy) do
    if strategy in valid(), do: {:ok, strategy}, else: {:error, "invalid proof strategy: #{strategy}. Valid: #{inspect(valid())}"}
  end
  def validate(_), do: {:error, "proof strategy must be an atom"}
end

defmodule TiannaraRuntime.Mathematics.Ontology.InferenceRule do
  @moduledoc "Phase 16.X.1 — InferenceRule: logical rule for proof construction."
  @enforce_keys [:name, :premises_pattern, :conclusion_pattern]
  defstruct [:name, :premises_pattern, :conclusion_pattern]
  @type t :: %__MODULE__{name: String.t(), premises_pattern: String.t(), conclusion_pattern: String.t()}
  @spec new(String.t(), String.t(), String.t()) :: {:ok, t()} | {:error, String.t()}
  def new(name, premises_pattern, conclusion_pattern) when is_binary(name) and is_binary(premises_pattern) and is_binary(conclusion_pattern) do
    ir = %__MODULE__{name: name, premises_pattern: premises_pattern, conclusion_pattern: conclusion_pattern}
    validate(ir)
  end
  @spec validate(t()) :: {:ok, t()} | {:error, String.t()}
  def validate(%__MODULE__{name: n}) when byte_size(n) == 0, do: {:error, "name must not be empty"}
  def validate(%__MODULE__{} = ir), do: {:ok, ir}
  def validate(_), do: {:error, "invalid"}
end

defmodule TiannaraRuntime.Mathematics.Ontology.AxiomSet do
  @moduledoc "Phase 16.X.1 — AxiomSet: collection of axioms."
  @enforce_keys [:id, :axioms]
  defstruct [:id, :axioms, :metadata]
  @type t :: %__MODULE__{id: String.t(), axioms: [String.t()], metadata: map()}
  @spec new(String.t(), [String.t()], keyword()) :: {:ok, t()} | {:error, String.t()}
  def new(id, axioms, opts \\ []) when is_binary(id) and is_list(axioms) do
    as = %__MODULE__{id: id, axioms: axioms, metadata: Keyword.get(opts, :metadata, %{})}
    validate(as)
  end
  @spec validate(t()) :: {:ok, t()} | {:error, String.t()}
  def validate(%__MODULE__{id: i, axioms: ax}) when byte_size(i) == 0 or length(ax) == 0, do: {:error, "id must not be empty and must have at least one axiom"}
  def validate(%__MODULE__{} = as), do: {:ok, as}
  def validate(_), do: {:error, "invalid"}
end

defmodule TiannaraRuntime.Mathematics.Ontology.ProofBundle do
  @moduledoc "Phase 16.X.1 — ProofBundle: collection of proofs."
  @enforce_keys [:id, :proofs]
  defstruct [:id, :proofs, :metadata]
  @type t :: %__MODULE__{id: String.t(), proofs: [String.t()], metadata: map()}
  @spec new(String.t(), [String.t()], keyword()) :: {:ok, t()} | {:error, String.t()}
  def new(id, proofs, opts \\ []) when is_binary(id) and is_list(proofs) do
    pb = %__MODULE__{id: id, proofs: proofs, metadata: Keyword.get(opts, :metadata, %{})}
    validate(pb)
  end
  @spec validate(t()) :: {:ok, t()} | {:error, String.t()}
  def validate(%__MODULE__{id: i, proofs: ps}) when byte_size(i) == 0 or length(ps) == 0, do: {:error, "id must not be empty and must have at least one proof"}
  def validate(%__MODULE__{} = pb), do: {:ok, pb}
  def validate(_), do: {:error, "invalid"}
end
