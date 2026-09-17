defmodule TiannaraRuntime.OS.Governance.Certification.CampaignAdapter do
  @moduledoc """
  CampaignAdapter — Behaviour contract for all 30 constitutional certification campaigns.

  Every campaign module must implement this behaviour, ensuring deterministic,
  evidence-driven execution with archaeologically reconstructible results.

  ## Contract

  Each campaign must:
  1. Accept a configuration map with scale, seed, and domain parameters
  2. Execute its validation logic using only live runtime state (no mocks)
  3. Return `{:ok, evidence}` with a signed evidence map on success
  4. Return `{:error, reason}` with failure details on failure
  5. Ensure all evidence is deterministically reproducible via replay
  """

  @type campaign_id :: String.t()
  @type campaign_name :: String.t()
  @type campaign_domain :: :constitutional_integrity | :runtime_integrity | :scientific_integrity | :evolution_integrity | :planetary_readiness | :civilizational_readiness
  @type campaign_tier :: 1 | 2 | 3 | 4 | 5 | 6

  @type scale_mode :: :quick | :standard | :full

  @type campaign_config :: %{
    scale: scale_mode(),
    seed: integer(),
    domain: campaign_domain() | nil,
    campaign_filter: [integer()] | nil,
    tick_rate: integer() | nil,
    max_iterations: integer() | nil
  }

  @type evidence :: %{
    campaign_id: campaign_id(),
    campaign_name: campaign_name(),
    domain: campaign_domain(),
    tier: campaign_tier(),
    status: :pass | :fail | :skip,
    evidence_map: map(),
    fingerprint: String.t(),
    executed_at: integer(),
    duration_ms: integer(),
    scale: scale_mode()
  }

  @type failure_reason :: %{
    campaign_id: campaign_id(),
    failure_type: :constitutional_violation | :runtime_error | :timeout | :resource_exhaustion | :evidence_missing,
    details: String.t(),
    evidence_map: map(),
    fingerprint: String.t(),
    executed_at: integer()
  }

  @type result :: {:ok, evidence()} | {:error, failure_reason()}

  @doc """
  Returns the campaign's unique identifier (e.g., "CC-001").
  """
  @callback campaign_id() :: campaign_id()

  @doc """
  Returns the campaign's human-readable name.
  """
  @callback campaign_name() :: campaign_name()

  @doc """
  Returns the campaign's domain classification.
  """
  @callback domain() :: campaign_domain()

  @doc """
  Returns the campaign's tier (1–6).
  """
  @callback tier() :: campaign_tier()

  @doc """
  Returns the list of campaign IDs this campaign depends on.
  """
  @callback dependencies() :: [campaign_id()]

  @doc """
  Executes the campaign with the given configuration.

  Must produce deterministic, reproducible results.
  No mock data, no hardcoded stubs, no hardcoded thresholds.
  """
  @callback execute(config :: campaign_config()) :: result()

  @doc """
  Returns a description of what this campaign validates.
  """
  @callback description() :: String.t()

  @doc """
  Returns the pass conditions for this campaign as a list of strings.
  """
  @callback pass_conditions() :: [String.t()]

  @optional_callbacks [description: 0, pass_conditions: 0]
end
