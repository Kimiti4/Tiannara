defmodule Tiannara.AEO do
  @moduledoc """
  Adaptive Execution Orchestrator (AEO).

  Translates a goal into a deterministic, inspectable execution graph and
  submits that graph only through an explicitly configured runtime adapter.
  Planning is not execution: a graph is returned as planned, and runtime
  submission reports acceptance only when the adapter returns a valid receipt.
  """

  @type execution_graph :: %{
          id: String.t(),
          intent: map(),
          nodes: [map()],
          status: :planned,
          created_at: DateTime.t()
        }

  @runtime_adapter_key :aeo_runtime_adapter

  @doc """
  Convert a non-empty string or goal map into a deterministic execution graph.

  Accepted map fields are `id`, `description`, and optional `priority`.
  Unknown fields are preserved as metadata; this function does not infer that
  arbitrary text is safe to execute.
  """
  @spec translate_intent(binary() | map()) :: {:ok, execution_graph()} | {:error, term()}
  def translate_intent(intent) when is_binary(intent) do
    description = String.trim(intent)

    if description == "" do
      {:error, :empty_intent}
    else
      build_graph(%{description: description, priority: :normal})
    end
  end

  def translate_intent(%{} = intent) do
    description = intent |> Map.get(:description, Map.get(intent, "description", ""))

    if not is_binary(description) or String.trim(description) == "" do
      {:error, :missing_description}
    else
      id = Map.get(intent, :id, Map.get(intent, "id"))
      priority = Map.get(intent, :priority, Map.get(intent, "priority", :normal))

      build_graph(%{
        id: normalize_id(id),
        description: String.trim(description),
        priority: normalize_priority(priority),
        metadata: Map.drop(intent, [:id, "id", :description, "description", :priority, "priority"])
      })
    end
  end

  def translate_intent(_), do: {:error, :invalid_intent}

  @doc """
  Rank domain candidates by descending numeric weight.

  Invalid weights are rejected rather than silently participating in routing.
  """
  def assemble_domain_team(_goal, domain_weights) when is_map(domain_weights) do
    if Enum.all?(domain_weights, fn {_domain, weight} -> is_number(weight) and weight >= 0 end) do
      {:ok,
       domain_weights
       |> Enum.sort_by(fn {_domain, weight} -> weight end, :desc)
       |> Enum.map(fn {domain, _weight} -> domain end)}
    else
      {:error, :invalid_domain_weights}
    end
  end

  def assemble_domain_team(_goal, _domain_weights), do: {:error, :invalid_domain_weights}

  @doc """
  Submit a planned graph through the configured runtime adapter.

  The adapter must implement `submit/1` and return
  `{:ok, %{execution_id: non_empty_binary, status: :accepted | :running}}`
  or `{:error, reason}`. A missing adapter, exception, or malformed receipt
  is an explicit failure, never a fabricated success.
  """
  def submit_to_runtime(%{id: id, nodes: nodes, status: :planned} = graph)
      when is_binary(id) and is_list(nodes) do
    case Application.get_env(:tiannara, @runtime_adapter_key) do
      nil ->
        {:error, :runtime_unavailable}

      adapter when is_atom(adapter) ->
        if Code.ensure_loaded?(adapter) and function_exported?(adapter, :submit, 1) do
          invoke_runtime(adapter, graph)
        else
          {:error, :invalid_runtime_adapter}
        end

      _ ->
        {:error, :invalid_runtime_adapter}
    end
  end

  def submit_to_runtime(_), do: {:error, :invalid_execution_graph}

  defp build_graph(intent) do
    stable_intent = %{
      id: intent[:id],
      description: intent.description,
      priority: intent.priority,
      metadata: Map.get(intent, :metadata, %{})
    }

    fingerprint =
      :crypto.hash(:sha256, :erlang.term_to_binary(stable_intent))
      |> Base.encode16(case: :lower)

    graph = %{
      id: "exec_" <> fingerprint,
      intent: stable_intent,
      nodes: [
        %{
          id: "goal_" <> fingerprint,
          operation: :evaluate_goal,
          input: intent.description,
          depends_on: [],
          requires_runtime_authorization: true
        }
      ],
      status: :planned,
      created_at: DateTime.utc_now()
    }

    {:ok, graph}
  end

  defp invoke_runtime(adapter, graph) do
    case adapter.submit(graph) do
      {:ok, %{execution_id: execution_id, status: status} = receipt}
      when is_binary(execution_id) and byte_size(execution_id) > 0 and
             status in [:accepted, :running] ->
        {:ok, %{status: status, receipt: receipt}}

      {:error, reason} ->
        {:error, reason}

      _ ->
        {:error, :invalid_runtime_receipt}
    end
  rescue
    error -> {:error, {:runtime_adapter_exception, error.__struct__}}
  catch
    kind, _reason -> {:error, {:runtime_adapter_failure, kind}}
  end

  defp normalize_id(id) when is_binary(id) and byte_size(id) > 0, do: id
  defp normalize_id(_), do: nil

  defp normalize_priority(priority) when priority in [:low, :normal, :high, :critical], do: priority
  defp normalize_priority(priority) when priority in ["low", "normal", "high", "critical"],
    do: String.to_existing_atom(priority)
  defp normalize_priority(_), do: :normal
end
