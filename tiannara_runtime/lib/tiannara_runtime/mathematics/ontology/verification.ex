defmodule TiannaraRuntime.Mathematics.Ontology.VerificationProperty do
  @moduledoc "Phase 16.X.1 — VerificationProperty: type-only, one of :correctness, :convergence, :safety, :stability, :consistency, :bounded."
  @type t :: :correctness | :convergence | :safety | :stability | :consistency | :bounded
  @spec valid() :: [t()]
  def valid, do: [:correctness, :convergence, :safety, :stability, :consistency, :bounded]
  @spec validate(atom()) :: {:ok, t()} | {:error, String.t()}
  def validate(prop) when is_atom(prop) do
    if prop in valid(), do: {:ok, prop}, else: {:error, "invalid property: #{prop}. Valid: #{inspect(valid())}"}
  end
  def validate(_), do: {:error, "verification property must be an atom"}
end

defmodule TiannaraRuntime.Mathematics.Ontology.VerificationResult do
  @moduledoc "Phase 16.X.1 — VerificationResult: type-only, one of :pass, :fail, :bounded."
  @type t :: :pass | :fail | :bounded
  @spec validate(atom()) :: {:ok, t()} | {:error, String.t()}
  def validate(:pass), do: {:ok, :pass}
  def validate(:fail), do: {:ok, :fail}
  def validate(:bounded), do: {:ok, :bounded}
  def validate(other), do: {:error, "invalid result: #{other}. Valid: :pass, :fail, :bounded"}
end

defmodule TiannaraRuntime.Mathematics.Ontology.MathematicalAssertion do
  @moduledoc "Phase 16.X.1 — MathematicalAssertion: verification result artifact (not a certificate)."
  @enforce_keys [:property_type, :system_hash, :result]
  defstruct [:id, :property_type, :system_hash, :result, :proof_hash, :counterexample_hash, :bound, :metadata]
  @type t :: %__MODULE__{id: String.t() | nil, property_type: TiannaraRuntime.Mathematics.Ontology.VerificationProperty.t(), system_hash: String.t(), result: TiannaraRuntime.Mathematics.Ontology.VerificationResult.t(), proof_hash: String.t() | nil, counterexample_hash: String.t() | nil, bound: non_neg_integer() | nil, metadata: map()}
  @spec new(atom(), String.t(), atom(), keyword()) :: {:ok, t()} | {:error, String.t()}
  def new(property_type, system_hash, result, opts \\ []) do
    ma = %__MODULE__{id: nil, property_type: property_type, system_hash: system_hash, result: result, proof_hash: Keyword.get(opts, :proof_hash), counterexample_hash: Keyword.get(opts, :counterexample_hash), bound: Keyword.get(opts, :bound), metadata: Keyword.get(opts, :metadata, %{})}
    validate(ma)
  end
  @spec validate(t()) :: {:ok, t()} | {:error, String.t()}
  def validate(%__MODULE__{system_hash: sh}) when byte_size(sh) == 0, do: {:error, "system_hash must not be empty"}
  def validate(%__MODULE__{result: :pass, proof_hash: nil}), do: {:error, "pass result must have a proof_hash"}
  def validate(%__MODULE__{result: :fail, counterexample_hash: nil}), do: {:error, "fail result must have a counterexample_hash"}
  def validate(%__MODULE__{} = ma), do: {:ok, ma}
  def validate(_), do: {:error, "invalid"}
  @spec id(t()) :: String.t()
  def id(%__MODULE__{} = ma), do: TiannaraRuntime.Mathematics.MathematicalID.from_canonical_map(%{"property_type" => ma.property_type, "system_hash" => ma.system_hash, "result" => ma.result, "proof_hash" => ma.proof_hash, "counterexample_hash" => ma.counterexample_hash, "bound" => ma.bound})
end

defmodule TiannaraRuntime.Mathematics.Ontology.Counterexample do
  @moduledoc "Phase 16.X.1 — Counterexample: witness to a violated property."
  @enforce_keys [:property, :witness]
  defstruct [:id, :property, :system_model_hash, :witness, :proof_hash, :metadata]
  @type t :: %__MODULE__{id: String.t() | nil, property: String.t(), system_model_hash: String.t() | nil, witness: String.t(), proof_hash: String.t() | nil, metadata: map()}
  @spec new(String.t(), String.t(), keyword()) :: {:ok, t()} | {:error, String.t()}
  def new(property, witness, opts \\ []) when is_binary(property) and is_binary(witness) do
    ce = %__MODULE__{id: nil, property: property, system_model_hash: Keyword.get(opts, :system_model_hash), witness: witness, proof_hash: Keyword.get(opts, :proof_hash), metadata: Keyword.get(opts, :metadata, %{})}
    validate(ce)
  end
  @spec validate(t()) :: {:ok, t()} | {:error, String.t()}
  def validate(%__MODULE__{property: p, witness: w}) when byte_size(p) == 0 or byte_size(w) == 0, do: {:error, "property and witness must not be empty"}
  def validate(%__MODULE__{} = ce), do: {:ok, ce}
  def validate(_), do: {:error, "invalid"}
end

defmodule TiannaraRuntime.Mathematics.Ontology.SystemModel do
  @moduledoc "Phase 16.X.1 — SystemModel: formal specification of a system for verification."
  @enforce_keys [:id, :specification]
  defstruct [:id, :specification, :components, :metadata]
  @type t :: %__MODULE__{id: String.t(), specification: String.t(), components: [String.t()], metadata: map()}
  @spec new(String.t(), String.t(), keyword()) :: {:ok, t()} | {:error, String.t()}
  def new(id, specification, opts \\ []) when is_binary(id) and is_binary(specification) do
    sm = %__MODULE__{id: id, specification: specification, components: Keyword.get(opts, :components, []), metadata: Keyword.get(opts, :metadata, %{})}
    validate(sm)
  end
  @spec validate(t()) :: {:ok, t()} | {:error, String.t()}
  def validate(%__MODULE__{id: i, specification: s}) when byte_size(i) == 0 or byte_size(s) == 0, do: {:error, "id and specification must not be empty"}
  def validate(%__MODULE__{} = sm), do: {:ok, sm}
  def validate(_), do: {:error, "invalid"}
end

defmodule TiannaraRuntime.Mathematics.Ontology.BoundedVerificationConfig do
  @moduledoc "Phase 16.X.1 — BoundedVerificationConfig: parameters for bounded verification."
  @enforce_keys [:max_steps]
  defstruct [:max_steps, :max_depth, :confidence]
  @type t :: %__MODULE__{max_steps: non_neg_integer(), max_depth: non_neg_integer() | nil, confidence: float() | nil}
  @spec new(non_neg_integer(), keyword()) :: {:ok, t()} | {:error, String.t()}
  def new(max_steps, opts \\ []) when is_integer(max_steps) and max_steps >= 0 do
    bc = %__MODULE__{max_steps: max_steps, max_depth: Keyword.get(opts, :max_depth), confidence: Keyword.get(opts, :confidence)}
    validate(bc)
  end
  @spec validate(t()) :: {:ok, t()} | {:error, String.t()}
  def validate(%__MODULE__{confidence: c}) when not is_nil(c) and (not is_number(c) or c < 0.0 or c > 1.0), do: {:error, "confidence must be in [0.0, 1.0] or nil"}
  def validate(%__MODULE__{} = bc), do: {:ok, bc}
  def validate(_), do: {:error, "invalid"}
end
