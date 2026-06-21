defmodule TiannaraOS.ResearchProgramEngine do
  @moduledoc """
  Manages the lifecycle ticks, budget deductions, and event emissions for active Research Programs.
  """

  alias TiannaraOS.ResearchProgram
  alias TiannaraOS.State
  alias TiannaraOS.Discovery
  alias TiannaraOS.DiscoveryExchange

  @doc """
  Ticks a research program to advance its lifecycle stage, deducting budget and emitting events.
  """
  @spec tick_program(ResearchProgram.t(), State.t()) :: {:ok, ResearchProgram.t(), State.t()} | {:error, any()}
  def tick_program(%ResearchProgram{status: :completed} = program, state), do: {:ok, program, state}
  def tick_program(%ResearchProgram{status: :suspended} = program, state), do: {:ok, program, state}
  # DEVELOPMENTAL IMMUNITY: Newborns and juveniles bypass the stage machine entirely.
  # They don't produce discoveries yet — that's expected. The stage machine would
  # drain compute/attention (2-5 units per transition) causing suspension.
  def tick_program(%ResearchProgram{life_stage: :newborn} = program, state), do: {:ok, program, state}
  def tick_program(%ResearchProgram{life_stage: :juvenile} = program, state), do: {:ok, program, state}

  def tick_program(%ResearchProgram{} = program, state) do
    now = System.system_time(:millisecond)
    program = if is_nil(program.started_at), do: %{program | started_at: now}, else: program

    case advance_stage(program.stage, program, state, now) do
      {:ok, updated_program, updated_state} ->
        # Save updated program to state
        new_programs = Map.put(updated_state.research_programs, updated_program.id, updated_program)
        new_state = %{updated_state | research_programs: new_programs}
        {:ok, updated_program, new_state}

      {:error, :insufficient_budget} ->
        # Suspend program on budget exhaustion
        suspended = %{program | status: :suspended, outcome: :failure}
        new_programs = Map.put(state.research_programs, suspended.id, suspended)
        {:ok, suspended, %{state | research_programs: new_programs}}

      {:error, reason} ->
        {:error, reason}
    end
  end

  # --- PRIVATE STAGE TRANSITIONS ---

  # 1. Goal Generation -> Hypothesis Generation
  defp advance_stage(:goal_generation, program, state, _now) do
    case deduct_budget(program, :attention, 2.0) do
      {:ok, updated} ->
        next_program = %{
          updated |
          stage: :hypothesis_generation,
          goals: ["Identify insecure dependencies", "Mitigate dependency CVEs"]
        }
        broadcast_event({:hypothesis_created, next_program.id})
        {:ok, next_program, state}
      {:error, reason} ->
        {:error, reason}
    end
  end

  # 2. Hypothesis Generation -> Experimentation
  defp advance_stage(:hypothesis_generation, program, state, _now) do
    case deduct_budget(program, :compute, 5.0) do
      {:ok, updated} ->
        hyp_id = String.to_atom("hyp_#{program.id}")
        next_program = %{
          updated |
          stage: :experimentation,
          hypotheses: [hyp_id | updated.hypotheses]
        }
        broadcast_event({:experiment_started, next_program.id})
        {:ok, next_program, state}
      {:error, reason} ->
        {:error, reason}
    end
  end

  # 3. Experimentation -> Evidence Synthesis
  defp advance_stage(:experimentation, program, state, _now) do
    case deduct_budget(program, :compute, 5.0) do
      {:ok, updated} ->
        exp_id = String.to_atom("exp_#{program.id}")
        next_program = %{
          updated |
          stage: :evidence_synthesis,
          active_experiments: [exp_id | updated.active_experiments]
        }
        broadcast_event({:evidence_collected, next_program.id})
        {:ok, next_program, state}
      {:error, reason} ->
        {:error, reason}
    end
  end

  # 4. Evidence Synthesis -> Discovery Candidate
  defp advance_stage(:evidence_synthesis, program, state, _now) do
    case deduct_budget(program, :credits, 10.0) do
      {:ok, updated} ->
        ev_id = String.to_atom("ev_#{program.id}")
        next_program = %{
          updated |
          stage: :discovery_candidate,
          evidence_ids: [ev_id | updated.evidence_ids]
        }
        broadcast_event({:discovery_candidate, next_program.id})
        {:ok, next_program, state}
      {:error, reason} ->
        {:error, reason}
    end
  end

  # 5. Discovery Candidate -> Completed
  defp advance_stage(:discovery_candidate, program, state, now) do
    # Propose discovery candidate
    discovery_id = String.to_atom("discovery_#{program.id}")
    
    # Instantiate the new Discovery struct
    new_discovery = %Discovery{
      id: discovery_id,
      source_world: program.world_id,
      evidence_ids: program.evidence_ids,
      theory_ids: [],
      origin_program_id: program.id,
      origin_institution_id: program.institution_id,
      origin_world_id: program.world_id,
      validation_level: :l1,
      status: :candidate,
      evidence_score: 0.7, # Starts above threshold
      validation_history: [%{level: :l1, timestamp: now, reason: "Proposed candidate by program #{program.id}"}]
    }

    # Register in state
    updated_discoveries = Map.put(state.discoveries, discovery_id, new_discovery)
    state_with_discovery = %{state | discoveries: updated_discoveries}

    # Complete program
    completed_program = %{
      program |
      status: :completed,
      outcome: :success,
      completed_at: now,
      discoveries: [discovery_id | program.discoveries]
    }

    broadcast_event({:program_discovery_created, program.id, discovery_id})
    broadcast_event({:program_completed, program.id})

    {:ok, completed_program, state_with_discovery}
  end

  # --- BUDGET UTILITY ---

  defp deduct_budget(program, key, amount) do
    current = Map.get(program.budget, key, 0.0)
    if current >= amount do
      {:ok, put_in(program.budget[key], current - amount)}
    else
      {:error, :insufficient_budget}
    end
  end

  # --- EVENT BROADCASTER ---

  defp broadcast_event(event) do
    if Process.whereis(Tiannara.PubSub) do
      Phoenix.PubSub.broadcast(Tiannara.PubSub, "tiannara_events", event)
    end
  end
end
