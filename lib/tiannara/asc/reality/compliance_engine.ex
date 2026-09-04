defmodule Tiannara.ASC.Reality.ComplianceEngine do
  use GenServer

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def check(artifact, target, params \\ %{}) do
    GenServer.call(__MODULE__, {:check, artifact, target, params})
  end

  def approve(deployment_id, reviewer) do
    GenServer.call(__MODULE__, {:approve, deployment_id, reviewer})
  end

  def reject(deployment_id, reviewer, reason) do
    GenServer.call(__MODULE__, {:reject, deployment_id, reviewer, reason})
  end

  def get_approval_status(deployment_id) do
    GenServer.call(__MODULE__, {:approval_status, deployment_id})
  end

  @impl true
  def init(:ok) do
    regulations = [
      %{id: :data_protection, name: "Data Protection Regulation", required_for: [:digital, :physical]},
      %{id: :safety_standard, name: "Operational Safety Standard", required_for: [:physical]},
      %{id: :ethical_guideline, name: "Ethical AI Deployment Guidelines", required_for: [:digital, :physical]},
      %{id: :environmental_regulation, name: "Environmental Impact Regulation", required_for: [:physical]},
      %{id: :quality_assurance, name: "Quality Assurance Standard", required_for: [:digital, :physical]}
    ]

    {:ok, %{approvals: %{}, regulations: regulations, pending_approvals: []}}
  end

  @impl true
  def handle_call({:check, artifact, target, _params}, _from, state) do
    applicable = Enum.filter(state.regulations, fn r ->
      r.required_for |> Enum.member?(target)
    end)

    checks = Enum.map(applicable, fn reg ->
      %{
        regulation: reg,
        status: :pending_review,
        requires_approval: true,
        checked_at: DateTime.utc_now()
      }
    end)

    compliance_id = "comp-#{:erlang.system_time(:millisecond)}"

    report = %{
      id: compliance_id,
      artifact: artifact,
      target: target,
      checks: checks,
      overall_status: :pending_approval,
      all_checks_pass: false,
      pending_approvals: length(checks),
      timestamp: DateTime.utc_now()
    }

    {:reply, {:ok, report},
     %{state | approvals: Map.put(state.approvals, compliance_id, report),
               pending_approvals: [compliance_id | state.pending_approvals]}}
  end

  def handle_call({:approve, compliance_id, reviewer}, _from, state) do
    case Map.get(state.approvals, compliance_id) do
      nil -> {:reply, {:error, :not_found}, state}
      report ->
        updated_checks = Enum.map(report.checks, fn c ->
          %{c | status: :approved}
        end)

        updated = report
        |> Map.put(:checks, updated_checks)
        |> Map.put(:overall_status, :approved)
        |> Map.put(:all_checks_pass, true)
        |> Map.put(:approved_by, reviewer)
        |> Map.put(:approved_at, DateTime.utc_now())
        |> Map.put(:pending_approvals, 0)

        {:reply, {:ok, updated},
         %{state | approvals: Map.put(state.approvals, compliance_id, updated),
                   pending_approvals: List.delete(state.pending_approvals, compliance_id)}}
    end
  end

  def handle_call({:reject, compliance_id, reviewer, reason}, _from, state) do
    case Map.get(state.approvals, compliance_id) do
      nil -> {:reply, {:error, :not_found}, state}
      report ->
        updated = report
        |> Map.put(:overall_status, :rejected)
        |> Map.put(:rejected_by, reviewer)
        |> Map.put(:rejection_reason, reason)
        |> Map.put(:rejected_at, DateTime.utc_now())

        {:reply, {:ok, updated},
         %{state | approvals: Map.put(state.approvals, compliance_id, updated),
                   pending_approvals: List.delete(state.pending_approvals, compliance_id)}}
    end
  end

  def handle_call({:approval_status, compliance_id}, _from, state) do
    {:reply, Map.get(state.approvals, compliance_id), state}
  end
end
