defmodule TiannaraRuntime.CausalDiscovery.InterventionPlan do
  @moduledoc """
  Phase 17.3 — InterventionPlan: a planned intervention from InterventionEngine.
  Content-addressed ID prefix: ip_
  """
  @enforce_keys [:target_variable, :intervention_type, :set_value]
  defstruct [
    :plan_id, :target_variable, :intervention_type, :set_value,
    :conditional_values, :do_operator, :graph_fingerprint,
    :expected_effect, :confidence_interval, :identifiability,
    :metadata
  ]

  @type intervention_type :: :atomic | :conditional | :stochastic
  @type identifiability :: :identified | :partial | :non_identifiable
  @type set_value :: :remove | {:fix, term()} | {:set_distribution, map()}

  @type t :: %__MODULE__{
    plan_id: String.t(),
    target_variable: String.t(),
    intervention_type: intervention_type(),
    set_value: set_value(),
    conditional_values: map() | nil,
    do_operator: String.t(),
    graph_fingerprint: String.t() | nil,
    expected_effect: float() | nil,
    confidence_interval: TiannaraRuntime.WorldModel.Ontology.Interval.t() | nil,
    identifiability: identifiability(),
    metadata: map()
  }

  @spec new(keyword()) :: {:ok, t()} | {:error, String.t()}
  def new(opts \\ []) do
    ip = %__MODULE__{
      plan_id: Keyword.get(opts, :plan_id),
      target_variable: Keyword.get(opts, :target_variable),
      intervention_type: Keyword.get(opts, :intervention_type, :atomic),
      set_value: Keyword.get(opts, :set_value),
      conditional_values: Keyword.get(opts, :conditional_values),
      do_operator: Keyword.get(opts, :do_operator, "do"),
      graph_fingerprint: Keyword.get(opts, :graph_fingerprint),
      expected_effect: Keyword.get(opts, :expected_effect),
      confidence_interval: Keyword.get(opts, :confidence_interval),
      identifiability: Keyword.get(opts, :identifiability, :non_identifiable),
      metadata: Keyword.get(opts, :metadata, %{})
    }
    with {:ok, ip} <- validate(ip),
         do: {:ok, ensure_id(ip)}
  end

  @spec validate(t()) :: {:ok, t()} | {:error, String.t()}
  def validate(%__MODULE__{target_variable: tv}) when is_nil(tv) or tv == "",
    do: {:error, "InterventionPlan target_variable must not be empty"}
  def validate(%__MODULE__{set_value: sv}) when is_nil(sv),
    do: {:error, "InterventionPlan set_value must not be nil"}
  def validate(%__MODULE__{intervention_type: it}) when it not in ~w(atomic conditional stochastic)a,
    do: {:error, "InterventionPlan intervention_type must be one of: atomic, conditional, stochastic"}
  def validate(%__MODULE__{identifiability: id}) when id not in ~w(identified partial non_identifiable)a,
    do: {:error, "InterventionPlan identifiability must be :identified, :partial, or :non_identifiable"}
  def validate(%__MODULE__{} = ip), do: {:ok, ip}
  def validate(_), do: {:error, "invalid InterventionPlan"}

  @spec compute_id(t()) :: String.t()
  def compute_id(%__MODULE__{} = ip) do
    raw = ip.target_variable <> Atom.to_string(ip.intervention_type) <> inspect(ip.set_value) <> (ip.graph_fingerprint || "")
    "ip_" <> (:crypto.hash(:sha256, raw) |> Base.encode16(case: :lower))
  end

  defp ensure_id(%__MODULE__{plan_id: nil} = ip), do: %{ip | plan_id: compute_id(ip)}
  defp ensure_id(%__MODULE__{} = ip), do: ip
end
