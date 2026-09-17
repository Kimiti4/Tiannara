defmodule TiannaraRuntime.WorldModel.Ontology.Intervention do
  @moduledoc """
  Phase 17 — Intervention: a do-operator that modifies a variable in a causal model.
  """
  @enforce_keys [:intervention_id, :target_variable, :set_value]
  defstruct [:intervention_id, :target_variable, :set_value, :do_operator, :description]

  @type set_value :: :remove | {:fix, term()} | {:set_distribution, map()}
  @type do_op :: :atomic | :conditional | :stochastic

  @type t :: %__MODULE__{
          intervention_id: String.t(),
          target_variable: String.t(),
          set_value: set_value(),
          do_operator: do_op(),
          description: String.t() | nil
        }

  @spec new(keyword()) :: {:ok, t()} | {:error, String.t()}
  def new(opts \\ []) do
    iv = %__MODULE__{
      intervention_id: Keyword.get(opts, :intervention_id, generate_id()),
      target_variable: Keyword.get(opts, :target_variable),
      set_value: Keyword.get(opts, :set_value),
      do_operator: Keyword.get(opts, :do_operator, :atomic),
      description: Keyword.get(opts, :description)
    }
    validate(iv)
  end

  @spec validate(t()) :: {:ok, t()} | {:error, String.t()}
  def validate(%__MODULE__{target_variable: tv}) when is_nil(tv) or tv == "",
    do: {:error, "Intervention target_variable must not be empty"}
  def validate(%__MODULE__{set_value: sv}) when is_nil(sv),
    do: {:error, "Intervention set_value must not be nil"}
  def validate(%__MODULE__{do_operator: dop}) when dop not in ~w(atomic conditional stochastic)a,
    do: {:error, "Intervention do_operator must be one of: atomic, conditional, stochastic"}
  def validate(%__MODULE__{} = iv), do: {:ok, iv}
  def validate(_), do: {:error, "invalid Intervention"}

  defp generate_id, do: "iv_" <> (:crypto.strong_rand_bytes(12) |> Base.encode16(case: :lower))
end

defmodule TiannaraRuntime.WorldModel.Ontology.CounterfactualModel do
  @moduledoc """
  Phase 17 — CounterfactualModel: the result of applying an intervention to a base model.
  """
  @enforce_keys [:counterfactual_id, :base_model_id, :intervention]
  defstruct [:counterfactual_id, :base_model_id, :intervention, :resulting_state, :fingerprint, :created_at]

  @type t :: %__MODULE__{
          counterfactual_id: String.t(),
          base_model_id: String.t(),
          intervention: TiannaraRuntime.WorldModel.Ontology.Intervention.t(),
          resulting_state: map() | nil,
          fingerprint: String.t() | nil,
          created_at: String.t()
        }

  @spec new(keyword()) :: {:ok, t()} | {:error, String.t()}
  def new(opts \\ []) do
    now = DateTime.utc_now() |> DateTime.to_iso8601()

    cf = %__MODULE__{
      counterfactual_id: Keyword.get(opts, :counterfactual_id, generate_id()),
      base_model_id: Keyword.get(opts, :base_model_id),
      intervention: Keyword.get(opts, :intervention),
      resulting_state: Keyword.get(opts, :resulting_state),
      fingerprint: Keyword.get(opts, :fingerprint),
      created_at: Keyword.get(opts, :created_at, now)
    }
    validate(cf)
  end

  @spec validate(t()) :: {:ok, t()} | {:error, String.t()}
  def validate(%__MODULE__{base_model_id: bm}) when is_nil(bm) or bm == "",
    do: {:error, "CounterfactualModel base_model_id must not be empty"}
  def validate(%__MODULE__{intervention: iv}) when is_nil(iv),
    do: {:error, "CounterfactualModel intervention must not be nil"}
  def validate(%__MODULE__{} = cf), do: {:ok, cf}
  def validate(_), do: {:error, "invalid CounterfactualModel"}

  defp generate_id, do: "cf_" <> (:crypto.strong_rand_bytes(16) |> Base.encode16(case: :lower))
end
