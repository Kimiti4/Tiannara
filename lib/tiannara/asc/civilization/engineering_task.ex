defmodule Tiannara.ASC.Civilization.EngineeringTask do
  @moduledoc """
  Phase 9: The Blackboard. 
  Represents a unit of engineering work flowing through the Guild.
  Agents react to its state and append their artifacts to its history.
  """
  
  defstruct [
    :id,
    :goal,
    :assigned_genome,
    
    # State Machine
    state: :pending, # :pending, :designed, :coded, :reviewing, :testing, :approved, :deployed, :rejected
    
    # Artifacts appended by Specialists
    design_doc: nil,
    patches: [],
    review_feedback: nil,
    test_outcome: nil,
    
    # Audit Trail
    history: []
  ]

  @type t :: %__MODULE__{
    id: String.t(),
    goal: String.t(),
    assigned_genome: map(),
    state: atom(),
    design_doc: map() | nil,
    patches: list(),
    review_feedback: String.t() | nil,
    test_outcome: map() | nil,
    history: list()
  }

  def log_event(%__MODULE__{} = task, agent, event, details) do
    entry = %{
      timestamp: System.system_time(:millisecond),
      agent: agent,
      event: event,
      details: details
    }
    %{task | history: [entry | task.history]}
  end
end
