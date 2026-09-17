defmodule TiannaraRuntime.Mathematics.Ontology.MathematicalProgram do
  @moduledoc "Phase 16.X.1 — MathematicalProgram: objectives, constraints, and mathematical objects."
  @enforce_keys [:objectives]
  defstruct [:id, :objectives, :constraints, :mathematical_objects, :metadata]
  @type t :: %__MODULE__{id: String.t() | nil, objectives: [String.t()], constraints: [String.t()], mathematical_objects: [String.t()], metadata: map()}
  @spec new([String.t()], keyword()) :: {:ok, t()} | {:error, String.t()}
  def new(objectives, opts \\ []) when is_list(objectives) do
    mp = %__MODULE__{id: nil, objectives: objectives, constraints: Keyword.get(opts, :constraints, []), mathematical_objects: Keyword.get(opts, :mathematical_objects, []), metadata: Keyword.get(opts, :metadata, %{})}
    validate(mp)
  end
  @spec validate(t()) :: {:ok, t()} | {:error, String.t()}
  def validate(%__MODULE__{objectives: o}) when length(o) == 0, do: {:error, "must have at least one objective"}
  def validate(%__MODULE__{} = mp), do: {:ok, mp}
  def validate(_), do: {:error, "invalid"}
end

defmodule TiannaraRuntime.Mathematics.Ontology.MathematicalExperiment do
  @moduledoc "Phase 16.X.1 — MathematicalExperiment: experiment within a mathematical program."
  @enforce_keys [:program_id]
  defstruct [:id, :program_id, :parameters, :results, :metadata]
  @type t :: %__MODULE__{id: String.t() | nil, program_id: String.t(), parameters: map(), results: map() | nil, metadata: map()}
  @spec new(String.t(), keyword()) :: {:ok, t()} | {:error, String.t()}
  def new(program_id, opts \\ []) when is_binary(program_id) do
    me = %__MODULE__{id: nil, program_id: program_id, parameters: Keyword.get(opts, :parameters, %{}), results: Keyword.get(opts, :results), metadata: Keyword.get(opts, :metadata, %{})}
    validate(me)
  end
  @spec validate(t()) :: {:ok, t()} | {:error, String.t()}
  def validate(%__MODULE__{program_id: pid}) when byte_size(pid) == 0, do: {:error, "program_id must not be empty"}
  def validate(%__MODULE__{} = me), do: {:ok, me}
  def validate(_), do: {:error, "invalid"}
end

defmodule TiannaraRuntime.Mathematics.Ontology.ArchaeologyRecord do
  @moduledoc "Phase 16.X.1 — ArchaeologyRecord: provenance for every mathematical artifact."
  @enforce_keys [:origin, :purpose, :owner]
  defstruct [:origin, :purpose, :owner, :dependencies, :lineage]
  @type t :: %__MODULE__{origin: String.t(), purpose: String.t(), owner: String.t(), dependencies: [String.t()], lineage: [String.t()]}
  @spec new(String.t(), String.t(), String.t(), keyword()) :: {:ok, t()} | {:error, String.t()}
  def new(origin, purpose, owner, opts \\ []) when is_binary(origin) and is_binary(purpose) and is_binary(owner) do
    r = %__MODULE__{origin: origin, purpose: purpose, owner: owner, dependencies: Keyword.get(opts, :dependencies, []), lineage: Keyword.get(opts, :lineage, [])}
    validate(r)
  end
  @spec validate(t()) :: {:ok, t()} | {:error, String.t()}
  def validate(%__MODULE__{origin: o, purpose: p, owner: ow}) when byte_size(o) == 0 or byte_size(p) == 0 or byte_size(ow) == 0, do: {:error, "origin, purpose, and owner must not be empty"}
  def validate(%__MODULE__{} = r), do: {:ok, r}
  def validate(_), do: {:error, "invalid"}
end
