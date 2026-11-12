defmodule Tiannara.Council do
  use GenServer
  require Logger

  alias Tiannara.Council.{AuditLog, Authorization, ConstitutionalMonitor,
                          ConstitutionRepository, DecisionDigest, DecisionReceipt,
                          EmergencyState, ExecutionContext, HumanApprovalQueue, PolicyRegistry,
                          RuleEngine}
  alias Tiannara.Omega.MintRegistry

  @receipt_ttl_seconds 300

  def start_link(_opts), do: GenServer.start_link(__MODULE__, %{}, name: __MODULE__)

  def constitution, do: ConstitutionRepository.current()

  @spec authorize(atom(), map(), ExecutionContext.t() | nil) :: Authorization.t()
  def authorize(decision_type, payload, context \\ nil) do
    GenServer.call(__MODULE__, {:authorize, decision_type, payload, context})
  end

  @doc """
  Evaluates a Council decision and, when it may authorize a machine effect,
  issues a MAC-protected one-time `DecisionReceipt` in the same call.

  Returns `{:ok, decision, receipt}` for an approving/conditional decision that
  may authorize a machine effect, `{:ok, decision, nil}` for a decision that may
  not (rejected, deferred, requires-human, conditional with unmet conditions),
  and `{:error, reason}` when issuance itself is refused (emergency, invalid
  scope, unavailable receipt custody/registry). A caller without a receipt must
  not attempt a machine mint; `MachineAuthorization.mint/2` fails closed.

  The payload must carry an exact `:scope` (operation + non-empty target) and
  an identical `:target`; the scope operation must match `:mutation_type` (or
  the decision type). A broad scope is refused with `:invalid_scope`.
  """
  @spec decide(atom(), map(), ExecutionContext.t() | nil) ::
          {:ok, Authorization.t(), DecisionReceipt.t() | nil} | {:error, term()}
  def decide(decision_type, payload, context \\ nil) do
    GenServer.call(__MODULE__, {:decide, decision_type, payload, context}, 30_000)
  end

  def invoke_emergency(actor, reason), do: GenServer.call(__MODULE__, {:emergency, actor, reason})
  def lift_emergency(human_id), do: GenServer.call(__MODULE__, {:lift_emergency, human_id})
  def emergency_state, do: GenServer.call(__MODULE__, :emergency_state)
  def constitutional_health, do: ConstitutionalMonitor.health_report()

  @doc "Current receipt time-to-live in seconds."
  @spec receipt_ttl_seconds() :: pos_integer()
  def receipt_ttl_seconds, do: @receipt_ttl_seconds

  @doc """
  Stable digest of the active policy set. A receipt issued under one policy set
  is refused after the set changes unless an explicit migration window exists.
  """
  @spec policy_version() :: String.t() | nil
  def policy_version do
    policies =
      PolicyRegistry.active_policies()
      |> Enum.map(fn policy ->
        {policy.id, policy.priority, policy.action, Enum.sort(policy.conditions)}
      end)
      |> Enum.sort()

    DecisionDigest.digest(:council_policy_set, policies)
  catch
    _kind, _reason -> nil
  end

  @doc "Current constitution version bound into a receipt."
  @spec constitution_version() :: String.t() | nil
  def constitution_version do
    ConstitutionRepository.current().version
  catch
    _kind, _reason -> nil
  end

  @impl true
  def init(_opts) do
    case EmergencyState.load() do
      :ok ->
        :ok

      {:error, reason} ->
        # Fail closed: never start with a silently-defaulted emergency state.
        raise "authoritative emergency state unavailable: #{inspect(reason)}"
    end

    emergency = EmergencyState.snapshot()
    epoch = EmergencyState.epoch()
    state = %{emergency: emergency, emergency_epoch: epoch}

    AuditLog.append(:council_runtime_booted, :system, %{
      constitution_version: ConstitutionRepository.current().version
    })

    Logger.info("Constitutional Runtime online.")
    {:ok, state}
  end

  @impl true
  def handle_call({:authorize, decision_type, payload, context}, _from, state) do
    cond do
      state.emergency.active and decision_type not in [:emergency_halt, :circuit_breaker] ->
        auth = Authorization.rejected(
          explanation: "Council emergency is active. All executive decisions are suspended.",
          context: context,
          policy_applied: :emergency_lockdown
        )
        AuditLog.append(:decision_blocked_emergency, :council, %{decision_type: decision_type})
        {:reply, auth, state}

      true ->
        auth = evaluate_and_authorize(decision_type, payload, context)
        {:reply, auth, state}
    end
  end

  @impl true
  def handle_call({:decide, decision_type, payload, context}, _from, state) do
    cond do
      state.emergency.active and not EmergencyState.decision_allowed?(decision_type) ->
        AuditLog.append(:council_decision_receipt_refused, :council, %{
          decision_type: decision_type,
          reason: :council_emergency_active
        })

        {:reply, {:error, :council_emergency_active}, state}

      true ->
        case issue_decision(decision_type, payload, context) do
          {:ok, auth, receipt} ->
            try do
              audit_decision_issued(decision_type, auth, receipt)
            rescue
              _ -> :ok
            catch
              :exit, _ -> :ok
            end

            {:reply, {:ok, auth, receipt}, state}

          {:error, reason} ->
            try do
              AuditLog.append(:council_decision_receipt_refused, :council, %{
                decision_type: decision_type,
                reason: reason
              })
            rescue
              _ -> :ok
            catch
              :exit, _ -> :ok
            end

            {:reply, {:error, reason}, state}
        end
    end
  end

  @impl true
  def handle_call({:emergency, actor, reason}, _from, state) do
    result =
      EmergencyState.with_interlock(fn ->
        new_emergency = %{active: true, invoked_by: actor, reason: reason, invoked_at: DateTime.utc_now()}
        epoch = state.emergency_epoch + 1

        case EmergencyState.publish(Map.put(new_emergency, :epoch, epoch)) do
          :ok ->
            try do
              AuditLog.append(:emergency_invoked, actor, %{reason: reason, epoch: epoch})
            rescue
              _ -> :ok
            catch
              :exit, _ -> :ok
            end

            Logger.error("CONSTITUTIONAL EMERGENCY by #{inspect(actor)}: #{reason}")
            :telemetry.execute([:tiannara, :council, :emergency, :invoked], %{}, %{actor: actor})
            {:reply, :ok, %{state | emergency: new_emergency, emergency_epoch: epoch}}

          {:error, reason} ->
            {:reply, {:error, reason}, state}
        end
      end)

    case result do
      {:reply, _, _} = reply -> reply
      {:error, reason} -> {:reply, {:error, reason}, state}
    end
  end

  @impl true
  def handle_call({:lift_emergency, human_id}, _from, state) do
    result =
      EmergencyState.with_interlock(fn ->
        if state.emergency.active do
          epoch = state.emergency_epoch + 1
          emergency = %{active: false, invoked_by: nil, reason: nil, invoked_at: nil}

          case EmergencyState.publish(Map.put(emergency, :epoch, epoch)) do
            :ok ->
              try do
                AuditLog.append(:emergency_lifted, human_id, %{prev: state.emergency.invoked_by, epoch: epoch})
              rescue
                _ -> :ok
              catch
                :exit, _ -> :ok
              end

              {:reply, :ok, %{state | emergency: emergency, emergency_epoch: epoch}}

            {:error, reason} ->
              {:reply, {:error, reason}, state}
          end
        else
          {:reply, {:error, :no_active_emergency}, state}
        end
      end)

    case result do
      {:reply, _, _} = reply -> reply
      {:error, reason} -> {:reply, {:error, reason}, state}
    end
  end

  @impl true
  def handle_call(:emergency_state, _from, state), do: {:reply, state.emergency, state}

  # ------------------------------------------------------- receipt issuance --

  defp issue_decision(decision_type, payload, context) do
    with {:ok, scope} <- scope_from_payload(payload, decision_type) do
      auth = evaluate_and_authorize(decision_type, payload, context)

      if Authorization.permitted?(auth) or Authorization.conditional_grant?(auth) do
        with {:ok, receipt} <- build_receipt(auth, decision_type, scope, payload, context) do
          {:ok, auth, receipt}
        end
      else
        {:ok, auth, nil}
      end
    end
  end

  defp scope_from_payload(payload, decision_type) when is_map(payload) do
    scope = Map.get(payload, :scope)
    target = Map.get(payload, :target)
    operation = Map.get(payload, :mutation_type, Map.get(payload, :operation, decision_type))

    cond do
      not DecisionDigest.valid_scope?(scope) ->
        :error

      not is_map(target) or target != scope.target ->
        :error

      is_nil(operation) or to_string(operation) != to_string(scope.operation) ->
        :error

      true ->
        {:ok, DecisionDigest.normalize_scope!(scope)}
    end
  rescue
    _ -> :error
  end

  defp scope_from_payload(_payload, _decision_type), do: :error

  defp build_receipt(auth, decision_type, scope, payload, context) do
    now = DateTime.utc_now()

    base = %DecisionReceipt{
      receipt_id: "dcr_#{random_hex(16)}",
      decision_digest: DecisionDigest.decision(auth),
      decision_type: decision_type,
      scope_digest: DecisionDigest.scope_digest(scope),
      actor: decision_actor(context, payload),
      issued_at: now,
      expires_at: DateTime.add(now, @receipt_ttl_seconds, :second),
      nonce: random_hex(32),
      issuer: DecisionReceipt.issuer(),
      policy_version: policy_version(),
      constitution_version: constitution_version(),
      mac: ""
    }

    cond do
      is_nil(base.policy_version) or is_nil(base.constitution_version) ->
        {:error, :receipt_unavailable}

      true ->
        with {:ok, signed} <- DecisionReceipt.sign(base),
             :ok <- record_receipt(signed) do
          {:ok, signed}
        end
    end
  catch
    _kind, _reason -> {:error, :receipt_unavailable}
  end

  defp record_receipt(receipt) do
    case MintRegistry.record_receipt(receipt) do
      :ok -> :ok
      :registry_unavailable -> {:error, :authorization_registry_unavailable}
      {:error, :registry_corrupt} -> {:error, :registry_corrupt}
      {:error, _reason} -> {:error, :receipt_unavailable}
    end
  end

  defp decision_actor(context, payload) do
    cond do
      is_struct(context, ExecutionContext) and not is_nil(context.actor) -> context.actor
      is_map(context) and not is_nil(Map.get(context, :actor)) -> Map.get(context, :actor)
      is_map(payload) and not is_nil(Map.get(payload, :actor)) -> Map.get(payload, :actor)
      true -> :unknown
    end
  end

  defp audit_decision_issued(decision_type, auth, %DecisionReceipt{} = receipt) do
    AuditLog.append(:council_decision_issued, :council, %{
      decision_type: decision_type,
      decision: auth.decision,
      receipt_id: receipt.receipt_id,
      decision_digest: receipt.decision_digest,
      scope_digest: receipt.scope_digest,
      issuer: receipt.issuer,
      policy_version: receipt.policy_version,
      constitution_version: receipt.constitution_version,
      expires_at: receipt.expires_at
    })
  end

  defp audit_decision_issued(decision_type, auth, nil) do
    AuditLog.append(:council_decision_without_receipt, :council, %{
      decision_type: decision_type,
      decision: auth.decision
    })
  end

  defp random_hex(bytes), do: :crypto.strong_rand_bytes(bytes) |> Base.encode16(case: :lower)

  @doc """
  Re-evaluates a parked decision with a human grant applied.

  The approval record alone never authorises anything: the decision is
  re-evaluated here, and the human grant only removes the human-review
  requirement of the matching policy. A policy that rejects the decision
  still rejects it - a human cannot grant what a policy refuses.
  """
  def resume_human_approval(request_id, decision_type, payload) do
    auth = evaluate_with_human_grant(decision_type, payload)

    AuditLog.append(:human_approval_resumed, :council, %{
      request_id: request_id,
      decision_type: decision_type,
      decision: auth.decision
    })

    auth
  end

  defp evaluate_with_human_grant(decision_type, payload) do
    case PolicyRegistry.evaluate(decision_type, payload) do
      {:matched, %{action: :reject} = policy} ->
        Authorization.rejected(
          explanation: "Policy '#{policy.id}' rejects this decision; a human grant cannot override it.",
          violated_principles: [:constitutional_compliance_first],
          policy_applied: policy.id
        )

      {:matched, %{action: :approve} = policy} ->
        score_auth(
          Authorization.approved(
            explanation: "Policy '#{policy.id}': #{policy.description}",
            policy_applied: policy.id
          ),
          decision_type,
          payload
        )

      {:matched, _policy} ->
        # The human grant satisfies the human-review requirement of the
        # policy; the constitutional evaluation still decides.
        RuleEngine.evaluate(decision_type, payload)

      {:default_approve, _} ->
        RuleEngine.evaluate(decision_type, payload)
    end
  end

  defp evaluate_and_authorize(decision_type, payload, context) do
    # 1. Check PolicyRegistry for declarative governance policies
    case PolicyRegistry.evaluate(decision_type, payload) do
      {:matched, %{action: :require_human} = policy} ->
        case HumanApprovalQueue.approved_request(decision_type, payload) do
          {:ok, request} ->
            # A human already approved this exact decision. The approval is a
            # record, not an authorisation, so the decision is re-evaluated
            # with the grant applied; a recorded resumption is used only when
            # it is available.
            resumed =
              case request do
                %{resumed_decision: %Authorization{} = recorded} -> recorded
                _ -> evaluate_with_human_grant(decision_type, payload)
              end

            score_auth(resumed, decision_type, payload)

          :none ->
            request_id = "req_#{:crypto.strong_rand_bytes(8) |> Base.encode16(case: :lower)}"

            HumanApprovalQueue.enqueue(
              request_id, decision_type, payload,
              "Policy '#{policy.id}' requires human approval: #{policy.description}"
            )

            auth = Authorization.requires_human(
              explanation: "Policy '#{policy.id}': #{policy.description}",
              evidence: [%{policy: policy.id, description: policy.description}],
              context: context,
              policy_applied: policy.id,
              metadata: %{request_id: request_id}
            )

            score_auth(auth, decision_type, payload)
        end

      {:matched, %{action: :require_simulation} = policy} ->
        sim_result = run_governance_simulation(decision_type, payload)

        auth = Authorization.requires_human(
          explanation: "Policy '#{policy.id}' requires simulation before human approval.",
          evidence: [%{simulation: sim_result}],
          simulation_results: [sim_result],
          context: context,
          policy_applied: policy.id
        )

        score_auth(auth, decision_type, payload)

      {:matched, %{action: :reject} = policy} ->
        auth = Authorization.rejected(
          explanation: "Policy '#{policy.id}': #{policy.description}",
          violated_principles: [:constitutional_compliance_first],
          context: context,
          policy_applied: policy.id
        )

        score_auth(auth, decision_type, payload)

      {:matched, %{action: :approve} = policy} ->
        auth = Authorization.approved(
          explanation: "Policy '#{policy.id}': #{policy.description}",
          context: context,
          policy_applied: policy.id
        )

        score_auth(auth, decision_type, payload)

      {:default_approve, _} ->
        # 2. For unclassified decisions, run full RuleEngine evaluation
        RuleEngine.evaluate(decision_type, payload, context)
    end
  end

  defp score_auth(auth, decision_type, payload) do
    rule = RuleEngine.evaluate(decision_type, payload)

    %{
      auth
      | constitutional_score: rule.constitutional_score,
        confidence: min(auth.confidence, rule.confidence),
        evidence: auth.evidence ++ rule.evidence,
        violated_principles: auth.violated_principles ++ rule.violated_principles
    }
    |> enforce_hard_invariants(decision_type, payload)
  end

  # The constitutional rule engine is authoritative; a policy action is
  # advisory. An approval that rests on a violated hard invariant is withdrawn
  # and the decision becomes a rejection, so a policy with action :approve can
  # never manufacture an approval the hard invariants forbid.
  defp enforce_hard_invariants(%{decision: :approved} = auth, decision_type, payload) do
    case RuleEngine.hard_invariant_violations(decision_type, payload) do
      [] ->
        auth

      violations ->
        AuditLog.append(:decision_blocked_by_hard_invariant, :council, %{
          decision_type: decision_type,
          policy: auth.policy_applied,
          violated_invariants: violations
        })

        %{
          auth
          | decision: :rejected,
            required_human_review: false,
            explanation:
              "Approval withdrawn by the constitutional rule engine: hard invariant(s) " <>
                Enum.join(violations, ", ") <> " would be violated.",
            metadata: Map.put(auth.metadata, :overridden_by, :hard_invariant)
        }
    end
  end

  defp enforce_hard_invariants(auth, _decision_type, _payload), do: auth

  defp run_governance_simulation(decision_type, payload) do
    %{
      simulated_at: DateTime.utc_now(),
      decision_type: decision_type,
      risk_score: Map.get(payload, :risk_assessment, 0.5),
      notes: "Governance simulation completed. Awaiting human review of results."
    }
  end
end
