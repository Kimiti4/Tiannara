defmodule Tiannara.ASC.Civilization.Specialists.Auditor do
  @moduledoc """
  Phase 9.1: The QA Gatekeeper. 
  Evaluates patches not just for correctness, but for Goal Alignment and Scope Creep.
  """
  alias Tiannara.ASC.Civilization.EngineeringTask
  alias Tiannara.ASC.Constitution
  alias Tiannara.ASC.Governance.SelfModificationGovernor
  def audit(%EngineeringTask{state: :coded, patches: patches} = task, active_goal) do
    patch = hd(patches)
    
    # 1. Check Self-Modification Governor
    with :allow <- SelfModificationGovernor.authorize_patch(patch.target_file) do
      
      # 2. Check Scope Creep (Complexity Cost)
      scope_creep = estimate_scope_creep(patch)
      
      # 3. Check Law Compliance (Does it violate Canonical Principles?)
      law_violations = check_law_compliance(patch)
      
      # 4. Run Value Formula
      proposal = %{
        domain: extract_domain(patch.target_file),
        expected_utility: 10.0,
        info_gain: 0.0,
        complexity_cost: scope_creep,
        compute_cost: 5.0,
        risk_factor: length(law_violations) * 10.0
      }
      
      case Constitution.evaluate_value(proposal, active_goal, task) do
        {:approve, value} ->
          task
          |> EngineeringTask.log_event(:auditor, :approved, "Value Score: #{value}")
          |> Map.put(:state, :approved)
          
        {:reject, reason} ->
          task
          |> EngineeringTask.log_event(:auditor, :rejected, reason)
          |> Map.put(:review_feedback, reason)
          |> Map.put(:state, :review_failed)
      end
    else
      {:deny, reason} ->
        task
        |> EngineeringTask.log_event(:auditor, :critical_rejection, reason)
        |> Map.put(:state, :rejected) # Hard reject, no loopback allowed for constitutional violations
    end
  end

  defp estimate_scope_creep(patch) do
    # Simple heuristic: Lines of code changed
    lines = patch.replacement_content |> String.split("\n") |> length()
    if lines > 50, do: 15.0, else: 2.0 # High penalty for massive diffs
  end

  defp check_law_compliance(_patch) do
    # In a full system, this would statically analyze the AST against the Law Registry
    [] 
  end
  
  defp extract_domain(file_path) do
    cond do
      String.contains?(file_path, "transfer") -> :transfer_physics
      String.contains?(file_path, "repair") -> :repair_ecology
      true -> :general
    end
  end
end
