defmodule TiannaraRuntime.Mathematics.Ontology.SymbolicExpression do
  @moduledoc "Phase 16.X.1 — SymbolicExpression: immutable, content-addressed expression tree."
  @enforce_keys [:type, :value]
  defstruct [:id, :type, :value, :children, :metadata]
  @type expression_type :: :constant | :variable | :function | :operator
  @type t :: %__MODULE__{id: String.t() | nil, type: expression_type(), value: term(), children: [t()], metadata: map()}
  @spec new(atom(), term(), keyword()) :: {:ok, t()} | {:error, String.t()}
  def new(type, value, opts \\ []) do
    e = %__MODULE__{id: nil, type: type, value: value, children: Keyword.get(opts, :children, []), metadata: Keyword.get(opts, :metadata, %{})}
    validate(e)
  end
  @spec validate(t()) :: {:ok, t()} | {:error, String.t()}
  def validate(%__MODULE__{value: v}) when is_nil(v), do: {:error, "value must not be nil"}
  def validate(%__MODULE__{} = e), do: {:ok, e}
  def validate(_), do: {:error, "invalid"}
  @spec id(t()) :: String.t()
  def id(%__MODULE__{} = e), do: TiannaraRuntime.Mathematics.MathematicalID.from_canonical_map(%{"type" => e.type, "value" => e.value, "children" => Enum.map(e.children || [], &id/1)})
end

defmodule TiannaraRuntime.Mathematics.Ontology.SymbolicRule do
  @moduledoc "Phase 16.X.1 — SymbolicRule: pattern → replacement transformation."
  @enforce_keys [:pattern, :replacement]
  defstruct [:pattern, :guard, :replacement]
  @type t :: %__MODULE__{pattern: String.t(), guard: String.t() | nil, replacement: String.t()}
  @spec new(String.t(), String.t(), String.t() | nil) :: {:ok, t()} | {:error, String.t()}
  def new(pattern, replacement, guard \\ nil) when is_binary(pattern) and is_binary(replacement) do
    r = %__MODULE__{pattern: pattern, guard: guard, replacement: replacement}
    validate(r)
  end
  @spec validate(t()) :: {:ok, t()} | {:error, String.t()}
  def validate(%__MODULE__{pattern: p, replacement: r}) when byte_size(p) == 0 or byte_size(r) == 0, do: {:error, "pattern and replacement must not be empty"}
  def validate(%__MODULE__{} = r), do: {:ok, r}
  def validate(_), do: {:error, "invalid"}
end

defmodule TiannaraRuntime.Mathematics.Ontology.RuleSet do
  @moduledoc "Phase 16.X.1 — RuleSet: ordered collection of symbolic rules."
  @enforce_keys [:id, :rules]
  defstruct [:id, :rules, :metadata]
  @type t :: %__MODULE__{id: String.t(), rules: [TiannaraRuntime.Mathematics.Ontology.SymbolicRule.t()], metadata: map()}
  @spec new(String.t(), [TiannaraRuntime.Mathematics.Ontology.SymbolicRule.t()], keyword()) :: {:ok, t()} | {:error, String.t()}
  def new(id, rules, opts \\ []) when is_binary(id) and is_list(rules) do
    rs = %__MODULE__{id: id, rules: rules, metadata: Keyword.get(opts, :metadata, %{})}
    validate(rs)
  end
  @spec validate(t()) :: {:ok, t()} | {:error, String.t()}
  def validate(%__MODULE__{id: i, rules: rs}) when byte_size(i) == 0 or length(rs) == 0, do: {:error, "id must not be empty and must have at least one rule"}
  def validate(%__MODULE__{} = rs), do: {:ok, rs}
  def validate(_), do: {:error, "invalid"}
end

defmodule TiannaraRuntime.Mathematics.Ontology.DomainRegistration do
  @moduledoc "Phase 16.X.1 — DomainRegistration: symbolic domain with rules and normalization."
  @enforce_keys [:domain, :rules]
  defstruct [:domain, :rules, :normalize_fn, :type_check_fn]
  @type t :: %__MODULE__{domain: atom(), rules: [TiannaraRuntime.Mathematics.Ontology.SymbolicRule.t()], normalize_fn: atom() | nil, type_check_fn: atom() | nil}
  @spec new(atom(), [TiannaraRuntime.Mathematics.Ontology.SymbolicRule.t()], keyword()) :: {:ok, t()} | {:error, String.t()}
  def new(domain, rules, opts \\ []) when is_atom(domain) and is_list(rules) do
    dr = %__MODULE__{domain: domain, rules: rules, normalize_fn: Keyword.get(opts, :normalize_fn), type_check_fn: Keyword.get(opts, :type_check_fn)}
    validate(dr)
  end
  @spec validate(t()) :: {:ok, t()} | {:error, String.t()}
  def validate(%__MODULE__{rules: rs}) when length(rs) == 0, do: {:error, "must have at least one rule"}
  def validate(%__MODULE__{} = dr), do: {:ok, dr}
  def validate(_), do: {:error, "invalid"}
end

defmodule TiannaraRuntime.Mathematics.Ontology.RewriteStep do
  @moduledoc "Phase 16.X.1 — RewriteStep: single step in a symbolic reduction."
  @enforce_keys [:step_number, :rule_applied, :expression_before, :expression_after]
  defstruct [:step_number, :rule_applied, :expression_before, :expression_after]
  @type t :: %__MODULE__{step_number: non_neg_integer(), rule_applied: String.t(), expression_before: TiannaraRuntime.Mathematics.Ontology.SymbolicExpression.t(), expression_after: TiannaraRuntime.Mathematics.Ontology.SymbolicExpression.t()}
  @spec new(non_neg_integer(), String.t(), TiannaraRuntime.Mathematics.Ontology.SymbolicExpression.t(), TiannaraRuntime.Mathematics.Ontology.SymbolicExpression.t()) :: {:ok, t()} | {:error, String.t()}
  def new(step_number, rule_applied, expr_before, expr_after) do
    rs = %__MODULE__{step_number: step_number, rule_applied: rule_applied, expression_before: expr_before, expression_after: expr_after}
    validate(rs)
  end
  @spec validate(t()) :: {:ok, t()} | {:error, String.t()}
  def validate(%__MODULE__{step_number: sn}) when not is_integer(sn) or sn < 0, do: {:error, "step_number must be a non-negative integer"}
  def validate(%__MODULE__{} = rs), do: {:ok, rs}
  def validate(_), do: {:error, "invalid"}
end

defmodule TiannaraRuntime.Mathematics.Ontology.RewriteLog do
  @moduledoc "Phase 16.X.1 — RewriteLog: sequence of rewrite steps."
  defstruct [:steps, :metadata]
  @type t :: %__MODULE__{steps: [TiannaraRuntime.Mathematics.Ontology.RewriteStep.t()], metadata: map()}
  @spec new([TiannaraRuntime.Mathematics.Ontology.RewriteStep.t()], keyword()) :: {:ok, t()} | {:error, String.t()}
  def new(steps, opts \\ []) when is_list(steps) do
    rl = %__MODULE__{steps: steps, metadata: Keyword.get(opts, :metadata, %{})}
    validate(rl)
  end
  @spec validate(t()) :: {:ok, t()} | {:error, String.t()}
  def validate(%__MODULE__{steps: []}), do: {:error, "must have at least one step"}
  def validate(%__MODULE__{} = rl), do: {:ok, rl}
  def validate(_), do: {:error, "invalid"}
end
