defmodule Tiannara.Omega.HumanDelivery.Authorization do
  @moduledoc """
  The mandatory human-authorization gate.

  A grant is bound to the exact explanation/candidate action identifier.
  Deployment and consequential-action consumers must validate that binding.
  """

  alias Tiannara.Omega.HumanDelivery.Explanation

  @enforce_keys [:authorization_id, :explanation_id]
  defstruct [
    :authorization_id,
    :explanation_id,
    :human_id,
    :granted_at,
    :ttl,
    :candidate_content_hash,
    :decision,
    :reason,
    :lineage,
    status: :prepared
  ]

  @type t :: %__MODULE__{}

  @default_ttl 3600

  @legal_transitions %{
    prepared: [:pending_authorization],
    pending_authorization: [:granted, :denied, :expired],
    granted: [:expired],
    denied: [],
    expired: []
  }

  def legal_transitions, do: @legal_transitions

  def prepare(%Explanation{} = explanation), do: prepare(%{explanation_id: explanation.explanation_id})

  def prepare(%{explanation_id: explanation_id}) when not is_nil(explanation_id) do
    {:ok,
     %__MODULE__{
       authorization_id: make_id(),
       explanation_id: explanation_id,
       status: :prepared,
       lineage: [explanation_id]
     }}
  end

  def prepare(_), do: {:error, :explanation_id_required}

  def request(%__MODULE__{status: :prepared} = auth),
    do: {:ok, %{auth | status: :pending_authorization}}

  def request(%__MODULE__{status: status}),
    do: {:error, {:illegal_transition, from: status, to: :pending_authorization}}

  def human_grant(%__MODULE__{status: :pending_authorization} = auth, human_id)
      when not is_nil(human_id),
      do: human_grant(auth, human_id, [])

  def human_grant(%__MODULE__{status: :pending_authorization}, nil),
    do: {:error, :human_id_required}

  def human_grant(%__MODULE__{status: status}, _human_id),
    do: {:error, {:illegal_transition, from: status, to: :granted}}

  def human_grant(%__MODULE__{status: :pending_authorization} = auth, human_id, opts)
      when not is_nil(human_id) do
    ttl = Keyword.get(opts, :ttl, @default_ttl)
    candidate_content_hash = Keyword.get(opts, :candidate_content_hash)
    action_id = Keyword.get(opts, :action_id, auth.explanation_id)

    if is_nil(action_id) do
      {:error, :action_id_required}
    else
      {:ok,
       %{auth |
         status: :granted,
         human_id: human_id,
         decision: :granted,
         granted_at: System.system_time(:second),
         ttl: ttl,
         candidate_content_hash: candidate_content_hash,
         explanation_id: action_id,
         lineage: auth.lineage ++ [{:granted_by, human_id}, {:action_id, action_id}]}}
    end
  end

  def human_grant(%__MODULE__{status: :pending_authorization}, nil, _opts),
    do: {:error, :human_id_required}

  def human_grant(%__MODULE__{status: status}, _human_id, _opts),
    do: {:error, {:illegal_transition, from: status, to: :granted}}

  def human_deny(%__MODULE__{status: :pending_authorization} = auth, reason)
      when not is_nil(reason) do
    {:ok,
     %{auth |
       status: :denied,
       decision: :denied,
       reason: reason,
       lineage: auth.lineage ++ [{:denied_for, reason}]}}
  end

  def human_deny(%__MODULE__{status: :pending_authorization}, nil),
    do: {:error, :reason_required}

  def human_deny(%__MODULE__{status: status}, _reason),
    do: {:error, {:illegal_transition, from: status, to: :denied}}

  def valid_for?(%__MODULE__{status: :granted, explanation_id: eid}, action_id),
    do: eid == action_id

  def valid_for?(_, _), do: false

  def expired?(grant, now \ nil)

  def expired?(%__MODULE__{status: :granted, granted_at: at, ttl: ttl}, now)
      when not is_nil(at) do
    now = now || System.system_time(:second)
    not is_nil(ttl) and now > at + ttl
  end

  def expired?(_, _), do: false

  def expire(%__MODULE__{status: :granted} = auth, now \ nil) do
    if expired?(auth, now) do
      {:ok, %{auth | status: :expired, lineage: auth.lineage ++ [:expired]}}
    else
      {:error, :not_yet_expired}
    end
  end

  def expire(%__MODULE__{status: status}, _now),
    do: {:error, {:illegal_transition, from: status, to: :expired}}

  defp make_id, do: "auth-#{System.unique_integer([:monotonic])}"
end
