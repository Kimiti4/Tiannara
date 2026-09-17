defmodule ObservatoryCore.Config.Artifact do
  @moduledoc """
  A configuration artifact — versioned, signed, traceable.

  Fields:
    id, version, created_at, checksum, signature, source,
    environment, parent_version, effective_from, data
  """

  defstruct [
    :id,
    :version,
    :created_at,
    :checksum,
    :signature,
    :source,
    :environment,
    :parent_version,
    :effective_from,
    :data
  ]

  @type t :: %__MODULE__{
          id: String.t(),
          version: non_neg_integer(),
          created_at: DateTime.t(),
          checksum: String.t(),
          signature: String.t() | nil,
          source: String.t(),
          environment: atom(),
          parent_version: non_neg_integer() | nil,
          effective_from: DateTime.t(),
          data: map()
        }

  @doc "Create a new config artifact from config data."
  def new(data, opts \\ []) do
    timestamp = DateTime.utc_now()
    checksum = :crypto.hash(:sha256, :erlang.term_to_binary(data)) |> Base.encode16(case: :lower)

    %__MODULE__{
      id: Ecto.UUID.generate(),
      version: opts[:version] || next_version(opts[:environment] || :dev),
      created_at: timestamp,
      checksum: checksum,
      signature: sign(checksum),
      source: opts[:source] || "loader",
      environment: opts[:environment] || :dev,
      parent_version: opts[:parent_version],
      effective_from: opts[:effective_from] || timestamp,
      data: data
    }
  end

  @doc "Verify an artifact's integrity: checksum + signature."
  def verify(%__MODULE__{checksum: cs, signature: sig, data: data}) do
    expected_cs =
      :crypto.hash(:sha256, :erlang.term_to_binary(data)) |> Base.encode16(case: :lower)

    expected_sig = sign(expected_cs)
    cs == expected_cs and sig == expected_sig
  end

  @doc "Produce a JSON-compatible map for persistence."
  def to_map(%__MODULE__{} = a) do
    %{
      id: a.id,
      version: a.version,
      created_at: a.created_at,
      checksum: a.checksum,
      signature: a.signature,
      source: a.source,
      environment: a.environment,
      parent_version: a.parent_version,
      effective_from: a.effective_from,
      data: a.data
    }
  end

  defp sign(checksum) do
    secret = Application.get_env(:observatory_core, :jwt_secret, "dev-secret")
    :crypto.mac(:hmac, :sha256, secret, checksum) |> Base.encode16(case: :lower)
  end

  defp next_version(env) do
    case :ets.lookup(:obs_config_artifacts, env) do
      [{_, %{version: v}}] -> v + 1
      _ -> 1
    end
  end
end

defmodule ObservatoryCore.Config.Artifact.ArtifactValidator do
  @schema NimbleOptions.new!(
            env: [type: {:in, [:dev, :test, :prod]}, default: :dev],
            database_url: [type: :string, default: "postgres://localhost:5432/observatory_core"],
            event_store_url: [
              type: :string,
              default: "postgres://localhost:5432/observatory_event_store"
            ],
            metrics_database_url: [
              type: :string,
              default: "postgres://localhost:5432/observatory_metrics"
            ],
            replay_database_url: [
              type: :string,
              default: "postgres://localhost:5432/observatory_replay"
            ],
            rbac_database_url: [
              type: :string,
              default: "postgres://localhost:5432/observatory_rbac"
            ],
            redis_url: [type: :string, default: "redis://localhost:6379"],
            jwt_secret: [type: :string, default: "dev-secret-change-in-production"],
            jwt_ttl_minutes: [type: :integer, default: 15],
            rbac_refresh_interval_ms: [type: :integer, default: 30_000],
            enable_audit_deltas: [type: :boolean, default: true],
            features: [type: :keyword_list, default: []]
          )

  def validate(config) do
    case NimbleOptions.validate(config, @schema) do
      {:ok, validated} -> {:ok, validated}
      {:error, errors} -> {:error, errors}
    end
  end
end
