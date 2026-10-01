defmodule Tiannara.AEO do
  @moduledoc """
  Adaptive Execution Orchestrator (AEO) - the bridge layer.
  
  Sits between Core and Runtime. Converts:
  - Intent → Execution Graphs
  
  Responsibilities:
  - Translate Core intent into Runtime-executable operations
  - Assemble domain teams based on Meta-Cognition guidance
  - Route execution requests to Runtime
  - Collect feedback from Runtime back to Core
  """

  @doc "Convert intent into execution graph."
  def translate_intent(%{id: id, goal: goal, steps: steps} = intent) when is_list(steps) and steps != [] do
    {:ok, %{id: id, goal: goal, steps: steps, source: intent}}
  end

  def translate_intent(_), do: {:error, :intent_requires_explicit_execution_steps}

  @doc "Assemble domain team for a goal based on meta-cognition weights."
  def assemble_domain_team(_goal, domain_weights) do
    sorted_domains =
      domain_weights
      |> Enum.sort_by(fn {_domain, weight} -> weight end, :desc)
      |> Enum.map(fn {domain, _weight} -> domain end)

    {:ok, sorted_domains}
  end

  @doc "Submit execution request to Runtime."
  def submit_to_runtime(%{id: _id} = execution_graph) do
    case Process.whereis(Tiannara.Runtime) do
      pid when is_pid(pid) -> GenServer.call(pid, {:submit_execution, execution_graph})
      _ -> {:error, :runtime_executor_unavailable}
    end
  catch
    :exit, reason -> {:error, {:runtime_executor_unavailable, reason}}
  end

  def submit_to_runtime(_), do: {:error, :invalid_execution_graph}
end
