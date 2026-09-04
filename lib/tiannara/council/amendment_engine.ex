defmodule Tiannara.Council.AmendmentEngine do
  use GenServer
  require Logger

  alias Tiannara.Council.{AuditLog, Constitution}

  @type amendment_id :: String.t()
  @type status ::
          :proposed
          | :simulating
          | :simulated
          | :evaluating
          | :evaluated
          | :awaiting_human
          | :approved
          | :rejected

  def start_link(_opts), do: GenServer.start_link(__MODULE__, %{}, name: __MODULE__)

  def propose(proposer, description, affected_principles, proposed_changes) do
    GenServer.call(__MODULE__, {:propose, proposer, description, affected_principles, proposed_changes})
  end

  def simulate(amendment_id), do: GenServer.call(__MODULE__, {:simulate, amendment_id})

  def evaluate(amendment_id), do: GenServer.call(__MODULE__, {:evaluate, amendment_id})

  def request_human_approval(amendment_id),
    do: GenServer.call(__MODULE__, {:request_human, amendment_id})

  def approve(amendment_id, human_id),
    do: GenServer.call(__MODULE__, {:approve, amendment_id, human_id})

  def reject(amendment_id, actor, reason),
    do: GenServer.call(__MODULE__, {:reject, amendment_id, actor, reason})

  def get(amendment_id), do: GenServer.call(__MODULE__, {:get, amendment_id})

  def all, do: GenServer.call(__MODULE__, :all)

  def healthy?, do: GenServer.call(__MODULE__, :healthy)

  @impl true
  def init(_opts) do
    {:ok, %{amendments: %{}, constitution: Constitution.v1()}}
  end

  @impl true
  def handle_call({:propose, proposer, description, affected, changes}, _from, state) do
    id = generate_id()

    amendment = %{
      id: id,
      proposer: proposer,
      description: description,
      affected_principles: affected,
      proposed_changes: changes,
      status: :proposed,
      simulation_report: nil,
      evaluation_report: nil,
      created_at: DateTime.utc_now(),
      history: [{:proposed, proposer, DateTime.utc_now()}]
    }

    AuditLog.append(:amendment_proposed, proposer, %{
      amendment_id: id,
      description: description,
      affected_principles: affected
    })

    new_state = put_in(state, [:amendments, id], amendment)
    {:reply, {:ok, id}, new_state}
  end

  @impl true
  def handle_call({:simulate, id}, _from, state) do
    case Map.fetch(state.amendments, id) do
      {:ok, %{status: :proposed} = a} ->
        report = run_simulation(a, state.constitution)

        updated =
          %{a | status: :simulated, simulation_report: report}
          |> append_history(:simulated, :council)

        AuditLog.append(:amendment_simulated, :council, %{
          amendment_id: id,
          risk_score: report.risk_score
        })

        {:reply, {:ok, report}, put_in(state, [:amendments, id], updated)}

      {:ok, a} ->
        {:reply, {:error, {:invalid_status, a.status}}, state}

      :error ->
        {:reply, {:error, :not_found}, state}
    end
  end

  @impl true
  def handle_call({:evaluate, id}, _from, state) do
    case Map.fetch(state.amendments, id) do
      {:ok, %{status: :simulated} = a} ->
        report = evaluate_against_principles(a, state.constitution)

        updated =
          %{a | status: :evaluated, evaluation_report: report}
          |> append_history(:evaluated, :council)

        AuditLog.append(:amendment_evaluated, :council, %{
          amendment_id: id,
          principle_alignment: report.principle_alignment
        })

        {:reply, {:ok, report}, put_in(state, [:amendments, id], updated)}

      {:ok, a} ->
        {:reply, {:error, {:invalid_status, a.status}}, state}

      :error ->
        {:reply, {:error, :not_found}, state}
    end
  end

  @impl true
  def handle_call({:request_human, id}, _from, state) do
    case Map.fetch(state.amendments, id) do
      {:ok, %{status: :evaluated} = a} ->
        updated = append_history(%{a | status: :awaiting_human}, :awaiting_human, :council)
        AuditLog.append(:amendment_awaiting_human, :council, %{amendment_id: id})
        {:reply, :ok, put_in(state, [:amendments, id], updated)}

      {:ok, a} ->
        {:reply, {:error, {:invalid_status, a.status}}, state}

      :error ->
        {:reply, {:error, :not_found}, state}
    end
  end

  @impl true
  def handle_call({:approve, id, human_id}, _from, state) do
    case Map.fetch(state.amendments, id) do
      {:ok, %{status: :awaiting_human} = a} ->
        new_constitution = apply_amendment(state.constitution, a)

        updated =
          append_history(%{a | status: :approved, approved_by: human_id}, :approved, human_id)

        AuditLog.append(:amendment_approved, human_id, %{
          amendment_id: id,
          new_constitution_version: new_constitution.version
        })

        new_state =
          state
          |> put_in([:amendments, id], updated)
          |> Map.put(:constitution, new_constitution)

        {:reply, {:ok, new_constitution}, new_state}

      {:ok, a} ->
        {:reply, {:error, {:invalid_status, a.status}}, state}

      :error ->
        {:reply, {:error, :not_found}, state}
    end
  end

  @impl true
  def handle_call({:reject, id, actor, reason}, _from, state) do
    case Map.fetch(state.amendments, id) do
      {:ok, a} when a.status in [:proposed, :simulated, :evaluated, :awaiting_human] ->
        updated = append_history(%{a | status: :rejected, rejection_reason: reason}, :rejected, actor)
        AuditLog.append(:amendment_rejected, actor, %{amendment_id: id, reason: reason})
        {:reply, :ok, put_in(state, [:amendments, id], updated)}

      {:ok, a} ->
        {:reply, {:error, {:invalid_status, a.status}}, state}

      :error ->
        {:reply, {:error, :not_found}, state}
    end
  end

  @impl true
  def handle_call({:get, id}, _from, state), do: {:reply, Map.fetch(state.amendments, id), state}

  @impl true
  def handle_call(:all, _from, state), do: {:reply, Map.values(state.amendments), state}

  @impl true
  def handle_call(:healthy, _from, state), do: {:reply, true, state}

  defp run_simulation(amendment, _constitution) do
    affected_count = length(amendment.affected_principles)

    touches_invariant =
      Enum.any?(amendment.proposed_changes, fn change ->
        change.type == :invariant
      end)

    risk_score =
      cond do
        touches_invariant -> 1.0
        affected_count >= 3 -> 0.8
        affected_count >= 1 -> 0.5
        true -> 0.2
      end

    %{
      risk_score: risk_score,
      touches_hard_invariant: touches_invariant,
      affected_principle_count: affected_count,
      simulated_at: DateTime.utc_now(),
      notes:
        "Simulation completed. Risk score derived from breadth of impact and invariant proximity."
    }
  end

  defp evaluate_against_principles(amendment, constitution) do
    alignments =
      Enum.map(constitution.principles, fn p ->
        alignment =
          if p.id in amendment.affected_principles do
            :strengthened
          else
            :unaffected
          end

        %{principle_id: p.id, alignment: alignment, weight: p.weight}
      end)

    weakened = alignments |> Enum.filter(&(&1.alignment == :weakened))

    overall_alignment =
      if Enum.empty?(weakened) do
        :aligned
      else
        :misaligned
      end

    %{
      overall_alignment: overall_alignment,
      principle_alignment: alignments,
      weakened_principles: Enum.map(weakened, & &1.principle_id),
      evaluated_at: DateTime.utc_now()
    }
  end

  defp apply_amendment(constitution, _amendment) do
    %{constitution | version: bump_version(constitution.version)}
  end

  defp bump_version(version) do
    case Version.parse(version <> ".0") do
      {:ok, v} -> "#{v.major}.#{v.minor}.#{v.patch + 1}"
      :error -> version <> "-amended"
    end
  end

  defp append_history(amendment, status, actor) do
    entry = {status, actor, DateTime.utc_now()}
    %{amendment | status: status, history: amendment.history ++ [entry]}
  end

  defp generate_id do
    "amend_#{:crypto.strong_rand_bytes(8) |> Base.encode16(case: :lower)}"
  end
end
