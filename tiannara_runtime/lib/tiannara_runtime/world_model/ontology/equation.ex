defmodule TiannaraRuntime.WorldModel.Ontology.Equation do
  @moduledoc """
  Phase 17 — Equation: a symbolic expression defining a variable's behavior.
  """
  @enforce_keys [:equation_id, :target_variable, :expression, :type]
  defstruct [
    :equation_id,
    :target_variable,
    :expression,
    :type,
    :derivation,
    :assumptions,
    :confidence,
    :mathematical_proof
  ]

  @type eq_type :: :algebraic | :differential | :integral | :difference
  @type derivation :: :learned | :first_principles | :expert_provided | :approximated

  @type t :: %__MODULE__{
          equation_id: String.t(),
          target_variable: String.t(),
          expression: map(),
          type: eq_type(),
          derivation: derivation(),
          assumptions: [String.t()],
          confidence: float(),
          mathematical_proof: String.t() | nil
        }

  @spec new(keyword()) :: {:ok, t()} | {:error, String.t()}
  def new(opts \\ []) do
    e = %__MODULE__{
      equation_id: Keyword.get(opts, :equation_id, generate_id()),
      target_variable: Keyword.get(opts, :target_variable),
      expression: Keyword.get(opts, :expression),
      type: Keyword.get(opts, :type),
      derivation: Keyword.get(opts, :derivation, :learned),
      assumptions: Keyword.get(opts, :assumptions, []),
      confidence: Keyword.get(opts, :confidence, 1.0),
      mathematical_proof: Keyword.get(opts, :mathematical_proof)
    }
    validate(e)
  end

  @spec validate(t()) :: {:ok, t()} | {:error, String.t()}
  def validate(%__MODULE__{target_variable: tv}) when is_nil(tv) or tv == "",
    do: {:error, "Equation target_variable must not be empty"}
  def validate(%__MODULE__{expression: e}) when is_nil(e),
    do: {:error, "Equation expression must not be nil"}
  def validate(%__MODULE__{type: t}) when t not in ~w(algebraic differential integral difference)a,
    do: {:error, "Equation type must be one of: algebraic, differential, integral, difference"}
  def validate(%__MODULE__{confidence: c}) when c < 0.0 or c > 1.0,
    do: {:error, "Equation confidence must be in [0.0, 1.0]"}
  def validate(%__MODULE__{} = e), do: {:ok, e}
  def validate(_), do: {:error, "invalid Equation"}

  defp generate_id, do: "eq_" <> (:crypto.strong_rand_bytes(12) |> Base.encode16(case: :lower))
end

defmodule TiannaraRuntime.WorldModel.Ontology.EquationSystem do
  @moduledoc """
  Phase 17 — EquationSystem: a set of equations defining a world model's dynamics.
  """
  @enforce_keys [:equations]
  defstruct [:equations, :algebraic_loops, :differential_index, :consistency_proof]

  @type t :: %__MODULE__{
          equations: [TiannaraRuntime.WorldModel.Ontology.Equation.t()],
          algebraic_loops: [String.t()],
          differential_index: non_neg_integer() | nil,
          consistency_proof: String.t() | nil
        }

  @spec new(keyword()) :: {:ok, t()} | {:error, String.t()}
  def new(opts \\ []) do
    es = %__MODULE__{
      equations: Keyword.get(opts, :equations, []),
      algebraic_loops: Keyword.get(opts, :algebraic_loops, []),
      differential_index: Keyword.get(opts, :differential_index),
      consistency_proof: Keyword.get(opts, :consistency_proof)
    }
    validate(es)
  end

  @spec validate(t()) :: {:ok, t()} | {:error, String.t()}
  def validate(%__MODULE__{equations: eqs}) when not is_list(eqs),
    do: {:error, "EquationSystem equations must be a list"}
  def validate(%__MODULE__{} = es), do: {:ok, es}
  def validate(_), do: {:error, "invalid EquationSystem"}
end
