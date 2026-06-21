defmodule Tiannara.Core.GoalSystem do
  @moduledoc """
  Goal System - Executive intent and goal management for Core.

  Manages:
  - What should happen?
  - Why should it happen?
  - What outcome is desired?
  
  Integrates with World Model for goal-driven intent generation.
  """

  defstruct [
    :goals,
    :active_goal,
    :history,
    :goal_confidence,
    :goal_strategies,
    :achievement_tracking
  ]

  alias Tiannara.Core.WorldModel
  alias Tiannara.Core.WorldModel.API

  @doc "Create a new goal system."
  def new do
    %__MODULE__{
      goals: [],
      active_goal: nil,
      history: [],
      goal_confidence: %{},
      goal_strategies: %{},
      achievement_tracking: %{}
    }
  end

  @doc "Add a goal to the system with World Model integration."
  def add_goal(system, goal_spec, world_model \\ nil) do
    # Create structured goal
    goal = %{
      id: generate_goal_id(),
      name: goal_spec.name,
      description: goal_spec.description,
      priority: goal_spec.priority || :medium,
      confidence: goal_spec.confidence || 0.5,
      created_at: DateTime.utc_now(),
      deadline: goal_spec.deadline,
      criteria: goal_spec.criteria || [],
      dependencies: goal_spec.dependencies || [],
      strategies: [],
      status: :active
    }
    
    # Add belief about goal to World Model
    if world_model do
      goal_belief = %{
        statement: "Goal created: #{goal.name}",
        confidence: goal.confidence,
        source: "goal_system",
        evidence: [goal.description],
        created_at: DateTime.utc_now(),
        last_verified: DateTime.utc_now()
      }
      
      updated_world_model = %{world_model | 
        beliefs: [goal_belief | world_model.beliefs]
      }
      
      # Create goal entity in World Model
      API.create_entity(
        "goal:#{goal.id}",
        "Goal",
        goal.name,
        %{priority: goal.priority, confidence: goal.confidence, strategies: []}
      )
      
      # Add goal to system
      new_goals = [goal | system.goals]
      updated_system = %{system | 
        goals: new_goals,
        goal_confidence: Map.put(system.goal_confidence, goal.id, goal.confidence)
      }
      
      {updated_system, updated_world_model}
    else
      # Add goal without World Model integration
      new_goals = [goal | system.goals]
      updated_system = %{system | 
        goals: new_goals,
        goal_confidence: Map.put(system.goal_confidence, goal.id, goal.confidence)
      }
      
      {updated_system, nil}
    end
  end

  @doc "Generate executive intent from goals and World Model state."
  def generate_intent(system, world_model) do
    # Analyze current goals and World Model state
    active_goals = Enum.filter(system.goals, & &1.status == :active)
    high_confidence_goals = Enum.filter(active_goals, & &1.confidence >= 0.7)
    
    # Extract relevant beliefs from World Model
    relevant_beliefs = find_goal_relevant_beliefs(world_model, high_confidence_goals)
    
    # Generate intent based on goals and reality state
    intent = %{
      source: "goal_system",
      goals: Enum.map(high_confidence_goals, & &1.name),
      priority: determine_system_priority(high_confidence_goals),
      confidence: calculate_intent_confidence(high_confidence_goals, relevant_beliefs),
      based_on: Enum.map(relevant_beliefs, & &1.statement),
      timestamp: DateTime.utc_now(),
      strategies: generate_goal_strategies(high_confidence_goals, world_model)
    }
    
    # Update World Model with intent
    intent_belief = %{
      statement: "Generated intent: #{intent.goals |> Enum.join(", ")}",
      confidence: intent.confidence,
      source: "goal_system",
      evidence: intent.based_on,
      created_at: DateTime.utc_now(),
      last_verified: DateTime.utc_now()
    }
    
    updated_world_model = %{world_model | 
      beliefs: [intent_belief | world_model.beliefs]
    }
    
    {intent, updated_world_model}
  end

  @doc "Update goal based on execution results and World Model feedback."
  def update_goal(system, goal_id, execution_results, world_model \\ nil) do
    case Enum.find(system.goals, & &1.id == goal_id) do
      nil ->
        {:error, :goal_not_found}
      goal ->
        # Calculate new goal confidence based on results
        new_confidence = calculate_goal_confidence(goal, execution_results)
        
        # Update goal in system
        updated_goals = Enum.map(system.goals, fn g ->
          if g.id == goal_id do
            %{g | 
              confidence: new_confidence,
              status: determine_goal_status(new_confidence),
              updated_at: DateTime.utc_now()
            }
          else
            g
          end
        end)
        
        updated_system = %{system | 
          goals: updated_goals,
          goal_confidence: Map.put(system.goal_confidence, goal_id, new_confidence)
        }
        
        # Update World Model with goal status change
        if world_model do
          goal_status_belief = %{
            statement: "Goal #{goal.name} status updated to #{determine_goal_status(new_confidence)}",
            confidence: new_confidence,
            source: "goal_execution",
            evidence: execution_results,
            created_at: DateTime.utc_now(),
            last_verified: DateTime.utc_now()
          }
          
          updated_world_model = %{world_model | 
            beliefs: [goal_status_belief | world_model.beliefs]
          }
          
          # Update goal entity in World Model
          API.update_entity("goal:#{goal_id}", %{confidence: new_confidence, status: determine_goal_status(new_confidence)})
          
          {updated_system, updated_world_model}
        else
          {updated_system, nil}
        end
    end
  end

  @doc "Set active goal based on priority and World Model context."
  def set_active_goal(system, world_model \\ nil) do
    active_goals = Enum.filter(system.goals, & &1.status == :active)
    
    if Enum.empty?(active_goals) do
      {system, nil}
    else
      # Select goal based on priority, confidence, and World Model context
      selected_goal = select_best_goal(active_goals, world_model)
      
      updated_system = %{system | active_goal: selected_goal.id}
      
      # Record active goal in World Model
      if world_model do
        active_goal_belief = %{
          statement: "Active goal set: #{selected_goal.name}",
          confidence: selected_goal.confidence,
          source: "goal_selection",
          evidence: ["priority: #{selected_goal.priority}"],
          created_at: DateTime.utc_now(),
          last_verified: DateTime.utc_now()
        }
        
        updated_world_model = %{world_model | 
          beliefs: [active_goal_belief | world_model.beliefs]
        }
        
        {updated_system, updated_world_model}
      else
        {updated_system, nil}
      end
    end
  end

  @doc "Get goal system statistics."
  def get_stats(system, world_model \\ nil) do
    stats = %{
      total_goals: length(system.goals),
      active_goals: Enum.count(system.goals, & &1.status == :active),
      completed_goals: Enum.count(system.goals, & &1.status == :completed),
      average_confidence: calculate_average_goal_confidence(system.goal_confidence),
      active_goal: system.active_goal,
      goal_distribution: get_goal_distribution(system.goals),
      strategy_count: Enum.sum(Map.values(system.goal_strategies))
    }
    
    if world_model do
      # Add World Model specific stats
      goal_entities = API.query_entities("Goal")
      world_model_stats = %{
        goal_entities_count: length(goal_entities),
        high_confidence_goal_beliefs: Enum.count(world_model.beliefs, fn belief ->
          String.contains?(belief.statement, "goal") and belief.confidence >= 0.7
        end)
      }
      
      Map.merge(stats, world_model_stats)
    else
      stats
    end
  end

  # Private helper functions

  defp generate_goal_id do
    "goal:#{System.system_time(:millisecond)}:#{:crypto.strong_rand_bytes(8) |> Base.encode16()}"
  end

  defp find_goal_relevant_beliefs(world_model, goals) do
    # Find beliefs relevant to the current goals
    goal_keywords = Enum.flat_map(goals, fn goal ->
      String.split(goal.name <> " " <> goal.description)
    end)
    
    Enum.filter(world_model.beliefs, fn belief ->
      belief_statement = String.downcase(belief.statement)
      Enum.any?(goal_keywords, fn keyword ->
        String.contains?(belief_statement, String.downcase(keyword))
      end)
    end)
  end

  defp determine_system_priority(goals) do
    if Enum.empty?(goals) do
      :none
    else
      # Priority based on highest priority goal with sufficient confidence
      highest_priority = Enum.max_by(goals, &goal_priority_weight(&1))
      
      if highest_priority.confidence >= 0.6 do
        highest_priority.priority
      else
        :low
      end
    end
  end

  defp goal_priority_weight(goal) do
    case goal.priority do
      :critical -> 1000
      :high -> 100
      :medium -> 10
      :low -> 1
    end
  end

  defp calculate_intent_confidence(goals, beliefs) do
    if Enum.empty?(goals) do
      0.0
    else
      goal_confidence = Enum.sum(Enum.map(goals, & &1.confidence)) / length(goals)
      belief_confidence = Enum.sum(Enum.map(beliefs, & &1.confidence)) / length(beliefs)
      
      # Weighted average
      0.6 * goal_confidence + 0.4 * belief_confidence
    end
  end

  defp generate_goal_strategies(goals, world_model) do
    Enum.map(goals, fn goal ->
      strategies = generate_strategies_for_goal(goal, world_model)
      %{goal.name => strategies}
    end)
  end

  defp generate_strategies_for_goal(goal, _world_model) do
    # Simplified strategy generation
    case goal.priority do
      :critical -> ["immediate_attention", "resource_allocation", "monitoring"]
      :high -> ["focused_effort", "regular_checkpoints", "backup_planning"]
      :medium -> ["progressive_implementation", "regular_reviews"]
      :low -> ["minimal_effort", "background_processing"]
    end
  end

  defp calculate_goal_confidence(goal, execution_results) do
    # Base confidence on goal's original confidence and execution results
    success_rate = calculate_success_rate(execution_results)
    
    # Adjust confidence based on success rate
    confidence_adjustment = success_rate * 0.3
    new_confidence = goal.confidence + confidence_adjustment
    
    # Clamp to valid range
    max(0.0, min(1.0, new_confidence))
  end

  defp calculate_success_rate(execution_results) do
    case execution_results do
      %{success: true, confidence: confidence} -> confidence
      %{success: false, confidence: confidence} -> 1.0 - confidence
      _ -> 0.5
    end
  end

  defp determine_goal_status(confidence) do
    cond do
      confidence >= 0.9 -> :completed
      confidence >= 0.7 -> :in_progress
      confidence >= 0.4 -> :stalled
      true -> :at_risk
    end
  end

  defp select_best_goal(goals, world_model) do
    # Score goals based on priority, confidence, and World Model context
    scored_goals = Enum.map(goals, fn goal ->
      score = calculate_goal_score(goal, world_model)
      {goal, score}
    end)
    
    # Select goal with highest score
    {selected_goal, _} = Enum.max_by(scored_goals, fn {_goal, score} -> score end)
    selected_goal
  end

  defp calculate_goal_score(goal, world_model) do
    priority_weight = case goal.priority do
      :critical -> 1000
      :high -> 100
      :medium -> 10
      :low -> 1
    end
    
    confidence_weight = goal.confidence * 100
    
    # Bonus for goals aligned with high-confidence beliefs
    alignment_bonus = calculate_goal_belief_alignment(goal, world_model) * 50
    
    priority_weight + confidence_weight + alignment_bonus
  end

  defp calculate_goal_belief_alignment(goal, world_model) do
    goal_keywords = String.split(goal.name <> " " <> goal.description)
    
    relevant_beliefs = Enum.filter(world_model.beliefs, fn belief ->
      belief_statement = String.downcase(belief.statement)
      Enum.any?(goal_keywords, fn keyword ->
        String.contains?(belief_statement, String.downcase(keyword))
      end)
    end)
    
    if Enum.empty?(relevant_beliefs) do
      0.0
    else
      Enum.sum(Enum.map(relevant_beliefs, & &1.confidence)) / length(relevant_beliefs)
    end
  end

  defp calculate_average_goal_confidence(goal_confidence) do
    if Enum.empty?(goal_confidence) do
      0.0
    else
      Enum.sum(Map.values(goal_confidence)) / map_size(goal_confidence)
    end
  end

  defp get_goal_distribution(goals) do
    goals
    |> Enum.group_by(& &1.priority)
    |> Enum.map(fn {priority, goal_list} -> {priority, length(goal_list)} end)
    |> Enum.into(%{})
  end
end
