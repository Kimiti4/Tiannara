defmodule Tiannara.Council.EmergencyState do
  @moduledoc """
  Authoritative Council emergency snapshot, replicated into `:persistent_term`
  for the machine-authority boundary (RL-565 / CP19.20).

  The Council GenServer remains the authority. It publishes this snapshot from
  `init/1`, `invoke_emergency/2` and `lift_emergency/1`. The mint registry, the
  machine mint and the effect boundary read the snapshot instead of calling
  back into Council, which avoids a Council <-> registry GenServer cycle and
  keeps the check fail-closed if Council is busy or unavailable.

  The snapshot carries a monotonically increasing `:epoch` so callers that
  need to reason about "emergency changed since issuance" can compare epochs.
  A missing snapshot means inactive only at the default value used before the
  Council process has ever booted; once Council has booted it always
  overwrites the term, including on restart.

  `delete_entity` and every other machine world effect are never
  emergency-allowed. Only the explicitly enumerated emergency decision types
  may be evaluated by Council during an emergency, and they still cannot mint a
  machine grant while the emergency is active.
  """

  @key {Tiannara.Council, :emergency_snapshot}

  @default %{
    active: false,
    invoked_by: nil,
    reason: nil,
    invoked_at: nil,
    epoch: 0
  }

  @emergency_allowed_decisions [:emergency_halt, :circuit_breaker]

  @doc "Publishes the authoritative snapshot. Called only from Council."
  @spec publish(map()) :: :ok
  def publish(%{active: active} = emergency) when is_boolean(active) do
    :persistent_term.put(@key, Map.merge(@default, emergency))
    :ok
  end

  @doc "Current emergency snapshot (default inactive before Council boots)."
  @spec snapshot() :: map()
  def snapshot, do: :persistent_term.get(@key, @default)

  @doc "True when Council emergency is active."
  @spec active?() :: boolean()
  def active?, do: snapshot().active == true

  @doc "Current emergency epoch (0 before the first Council boot)."
  @spec epoch() :: non_neg_integer()
  def epoch, do: Map.get(snapshot(), :epoch, 0)

  @doc "Decision types Council may still evaluate while the emergency is active."
  @spec emergency_allowed_decisions() :: [atom()]
  def emergency_allowed_decisions, do: @emergency_allowed_decisions

  @doc "True when this decision type may be evaluated during an emergency."
  @spec decision_allowed?(atom()) :: boolean()
  def decision_allowed?(decision_type), do: decision_type in @emergency_allowed_decisions

  @doc "True when this effect operation may execute during an emergency."
  @spec effect_allowed?(atom() | String.t()) :: boolean()
  def effect_allowed?(_operation), do: false

  @doc false
  # Test support only: clears the snapshot so a suite that never starts the
  # real Council process is not influenced by a previous test's emergency.
  @spec reset_test_state() :: :ok
  def reset_test_state do
    if Application.get_env(:tiannara, :allow_test_receipt_signing, false) == true do
      :persistent_term.put(@key, @default)
      :ok
    else
      {:error, :not_allowed}
    end
  end
end
