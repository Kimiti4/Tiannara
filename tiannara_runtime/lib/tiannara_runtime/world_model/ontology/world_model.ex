defmodule TiannaraRuntime.WorldModel.Ontology.WorldModel do
  @moduledoc """
  Phase 17 — WorldModel: the central artifact of the world modeling system.
  A constitutionally certified model carries guarantees of mathematical
  consistency, causal soundness, evidence fidelity, and replay determinism.
  """
  @enforce_keys [:name, :domain, :state_space]
  defstruct [
    :model_id,
    :version,
    :name,
    :domain,
    :state_space,
    :variables,
    :parameters,
    :equations,
    :causal_graph,
    :observation_model,
    :constraints,
    :metadata,
    :evidence_roots,
    :certificate,
    :status,
    :fingerprint,
    :created_at
  ]

  @type domain :: :engineering | :physics | :chemistry | :mathematics | :economics | :ecology | :social | :cosmology | :geology | :biology
  @type model_status :: :draft | :validated | :operational | :deprecated | :archived

  @type t :: %__MODULE__{
          model_id: String.t() | nil,
          version: non_neg_integer(),
          name: String.t(),
          domain: domain(),
          state_space: TiannaraRuntime.WorldModel.Ontology.StateSpace.t(),
          variables: [TiannaraRuntime.WorldModel.Ontology.Variable.t()],
          parameters: [TiannaraRuntime.WorldModel.Ontology.Parameter.t()],
          equations: TiannaraRuntime.WorldModel.Ontology.EquationSystem.t() | nil,
          causal_graph: TiannaraRuntime.WorldModel.Ontology.CausalGraph.t() | nil,
          observation_model: TiannaraRuntime.WorldModel.Ontology.ObservationModel.t() | nil,
          constraints: [map()],
          metadata: map(),
          evidence_roots: [String.t()],
          certificate: TiannaraRuntime.WorldModel.Ontology.ModelCertificate.t() | nil,
          status: model_status(),
          fingerprint: String.t() | nil,
          created_at: String.t()
        }

  @spec new(keyword()) :: {:ok, t()} | {:error, String.t()}
  def new(opts \\ []) do
    now = DateTime.utc_now() |> DateTime.to_iso8601()

    model = %__MODULE__{
      model_id: Keyword.get(opts, :model_id, generate_id()),
      version: Keyword.get(opts, :version, 1),
      name: Keyword.get(opts, :name),
      domain: Keyword.get(opts, :domain),
      state_space: Keyword.get(opts, :state_space),
      variables: Keyword.get(opts, :variables, []),
      parameters: Keyword.get(opts, :parameters, []),
      equations: Keyword.get(opts, :equations),
      causal_graph: Keyword.get(opts, :causal_graph),
      observation_model: Keyword.get(opts, :observation_model),
      constraints: Keyword.get(opts, :constraints, []),
      metadata: Keyword.get(opts, :metadata, %{}),
      evidence_roots: Keyword.get(opts, :evidence_roots, []),
      certificate: Keyword.get(opts, :certificate),
      status: Keyword.get(opts, :status, :draft),
      fingerprint: Keyword.get(opts, :fingerprint),
      created_at: Keyword.get(opts, :created_at, now)
    }

    validate(model)
  end

  @spec validate(t()) :: {:ok, t()} | {:error, String.t()}
  def validate(%__MODULE__{name: name}) when is_nil(name) or name == "",
    do: {:error, "WorldModel name must not be empty"}
  def validate(%__MODULE__{domain: domain}) when is_nil(domain),
    do: {:error, "WorldModel domain must not be nil"}
  def validate(%__MODULE__{state_space: %_{}} = model), do: {:ok, model}
  def validate(%__MODULE__{state_space: nil}),
    do: {:error, "WorldModel state_space must not be nil"}
  def validate(_), do: {:error, "invalid WorldModel struct"}

  defp generate_id, do: "wm_" <> (:crypto.strong_rand_bytes(16) |> Base.encode16(case: :lower))
end

defmodule TiannaraRuntime.WorldModel.Ontology.StateSpace do
  @moduledoc """
  Phase 17 — StateSpace: defines the dimensional structure and bounds of a world model.
  """
  @enforce_keys [:dimensions, :variable_order]
  defstruct [:dimensions, :variable_order, :bounds, :default_initial, :support_type]

  @type support_type :: :continuous | :discrete | :mixed

  @type t :: %__MODULE__{
          dimensions: non_neg_integer(),
          variable_order: [String.t()],
          bounds: map(),
          default_initial: map(),
          support_type: support_type()
        }

  @spec new(keyword()) :: {:ok, t()} | {:error, String.t()}
  def new(opts \\ []) do
    ss = %__MODULE__{
      dimensions: Keyword.get(opts, :dimensions, 0),
      variable_order: Keyword.get(opts, :variable_order, []),
      bounds: Keyword.get(opts, :bounds, %{}),
      default_initial: Keyword.get(opts, :default_initial, %{}),
      support_type: Keyword.get(opts, :support_type, :continuous)
    }
    validate(ss)
  end

  @spec validate(t()) :: {:ok, t()} | {:error, String.t()}
  def validate(%__MODULE__{dimensions: d, variable_order: vo}) when d != length(vo),
    do: {:error, "StateSpace dimensions must match variable_order length"}
  def validate(%__MODULE__{} = ss), do: {:ok, ss}
  def validate(_), do: {:error, "invalid StateSpace"}
end
