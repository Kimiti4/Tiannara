defmodule TiannaraOS.ResearchProgramEngine do
  @moduledoc """
  Manages the lifecycle ticks, budget deductions, and event emissions for active Research Programs.
  """

  alias TiannaraOS.ResearchProgram
  alias TiannaraOS.State
  alias TiannaraOS.Discovery

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
  #
  # A ResearchProgram is only allowed to advance when a real downstream
  # capability returns evidence. The former implementation fabricated goals,
  # hypothesis IDs, experiment IDs, evidence scores and successful discoveries.
  # Those values are now explicitly unavailable until the corresponding
  # executor/validator is connected.

  defp advance_stage(stage, _program, _state, _now) do
    {:error, {:research_capability_unavailable, stage}}
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
