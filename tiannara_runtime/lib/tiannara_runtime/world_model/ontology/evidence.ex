defmodule TiannaraRuntime.WorldModel.Ontology.Evidence do
  @moduledoc """
  Phase 17 — Evidence: an immutable, fingerprintable set of observations
  used as input to the world model pipeline.

  Evidence is classified by type and carries a Merkle root of all
  constituent observation fingerprints for replay verification.
  """

  @enforce_keys [:evidence_id, :domain]
  defstruct [
    :evidence_id,
    :domain,
    :source,
    :classification,
    :observations,
    :observation_count,
    :evidence_root,
    :time_window,
    :metadata,
    :created_at
  ]

  @type classification :: :controlled_experiment | :natural_observation | :simulation_output | :mixed
  @type source :: :observation_registry | :experiment | :simulation | :external

  @type t :: %__MODULE__{
          evidence_id: String.t(),
          domain: atom(),
          source: source(),
          classification: classification(),
          observations: [map()],
          observation_count: non_neg_integer(),
          evidence_root: String.t(),
          time_window: map() | nil,
          metadata: map(),
          created_at: String.t()
        }

  @spec new(keyword()) :: {:ok, t()} | {:error, String.t()}
  def new(opts \\ []) do
    now = DateTime.utc_now() |> DateTime.to_iso8601()

    evidence = %__MODULE__{
      evidence_id: Keyword.get(opts, :evidence_id, generate_id()),
      domain: Keyword.get(opts, :domain),
      source: Keyword.get(opts, :source, :observation_registry),
      classification: Keyword.get(opts, :classification, :mixed),
      observations: Keyword.get(opts, :observations, []),
      observation_count: Keyword.get(opts, :observation_count, 0),
      evidence_root: Keyword.get(opts, :evidence_root),
      time_window: Keyword.get(opts, :time_window),
      metadata: Keyword.get(opts, :metadata, %{}),
      created_at: Keyword.get(opts, :created_at, now)
    }

    validate(evidence)
  end

  @spec validate(t()) :: {:ok, t()} | {:error, String.t()}
  def validate(%__MODULE__{domain: d}) when is_nil(d),
    do: {:error, "Evidence domain must not be nil"}
  def validate(%__MODULE__{classification: c}) when c not in ~w(controlled_experiment natural_observation simulation_output mixed unknown)a,
    do: {:error, "Evidence classification must be one of: controlled_experiment, natural_observation, simulation_output, mixed, unknown"}
  def validate(%__MODULE__{observations: obs, observation_count: count}) when length(obs) != count,
    do: {:error, "Evidence observations count mismatch"}
  def validate(%__MODULE__{} = e), do: {:ok, e}
  def validate(_), do: {:error, "invalid Evidence"}

  defp generate_id, do: "ev_#{:crypto.strong_rand_bytes(16) |> Base.encode16(case: :lower)}"
end
