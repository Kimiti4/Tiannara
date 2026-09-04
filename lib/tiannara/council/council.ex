defmodule Tiannara.Council do
  use GenServer
  require Logger

  alias Tiannara.Council.{AuditLog, Authorization, ConstitutionalMonitor,
                          ConstitutionRepository, ExecutionContext, HumanApprovalQueue, PolicyRegistry, RuleEngine}

  def start_link(_opts), do: GenServer.start_link(__MODULE__, %{}, name: __MODULE__)

  def constitution, do: ConstitutionRepository.current()

  @spec authorize(atom(), map(), ExecutionContext.t() | nil) :: Authorization.t()
  def authorize(decision_type, payload, context \\ nil) do
    GenServer.call(__MODULE__, {:authorize, decision_type, payload, context})
  end

  def invoke_emergency(actor, reason), do: GenServer.call(__MODULE__, {:emergency, actor, reason})
  def lift_emergency(human_id), do: GenServer.call(__MODULE__, {:lift_emergency, human_id})
  def emergency_state, do: GenServer.call(__MODULE__, :emergency_state)
  def constitutional_health, do: ConstitutionalMonitor.health_report()

  @impl true
  def init(_opts) do
    state = %{emergency: %{active: false, invoked_by: nil, reason: nil, invoked_at: nil}}

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
  def handle_call({:emergency, actor, reason}, _from, state) do
    new_emergency = %{active: true, invoked_by: actor, reason: reason, invoked_at: DateTime.utc_now()}
    AuditLog.append(:emergency_invoked, actor, %{reason: reason})
    Logger.error("CONSTITUTIONAL EMERGENCY by #{inspect(actor)}: #{reason}")

    :telemetry.execute([:tiannara, :council, :emergency, :invoked], %{}, %{actor: actor})
    {:reply, :ok, %{state | emergency: new_emergency}}
  end

  @impl true
  def handle_call({:lift_emergency, human_id}, _from, state) do
    if state.emergency.active do
      AuditLog.append(:emergency_lifted, human_id, %{prev: state.emergency.invoked_by})
      {:reply, :ok, %{state | emergency: %{active: false, invoked_by: nil, reason: nil, invoked_at: nil}}}
    else
      {:reply, {:error, :no_active_emergency}, state}
    end
  end

  @impl true
  def handle_call(:emergency_state, _from, state), do: {:reply, state.emergency, state}

  defp evaluate_and_authorize(decision_type, payload, context) do
    # 1. Check PolicyRegistry for declarative governance policies
    case PolicyRegistry.evaluate(decision_type, payload) do
      {:matched, %{action: :require_human} = policy} ->
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

    %{auth |
      constitutional_score: rule.constitutional_score,
      confidence: min(auth.confidence, rule.confidence),
      evidence: auth.evidence ++ rule.evidence,
      violated_principles: auth.violated_principles ++ rule.violated_principles
    }
  end

  defp run_governance_simulation(decision_type, payload) do
    %{
      simulated_at: DateTime.utc_now(),
      decision_type: decision_type,
      risk_score: Map.get(payload, :risk_assessment, 0.5),
      notes: "Governance simulation completed. Awaiting human review of results."
    }
  end
end
