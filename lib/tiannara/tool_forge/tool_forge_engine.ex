defmodule Tiannara.ToolForge.ToolForgeEngine do
  use GenServer
  require Logger

  alias Tiannara.ToolForge.{NeedDetector, ToolArchitect, ToolBuilder}
  alias Tiannara.ToolForge.Domain.{ToolNeed, ToolSpecification, GeneratedTool}

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc "Triggers the full tool engineering pipeline for a need."
  def engineer_tool(%ToolNeed{} = need) do
    GenServer.call(__MODULE__, {:engineer, need}, 120_000)
  end

  @doc "Triggers need detection and engineers the highest-priority tool."
  def detect_and_engineer(system_state \\ %{}) do
    GenServer.call(__MODULE__, {:detect_and_engineer, system_state}, 120_000)
  end

  @doc "Returns all tools built by ToolForge."
  def built_tools, do: GenServer.call(__MODULE__, :built_tools)

  @doc "Returns ToolForge statistics."
  def stats, do: GenServer.call(__MODULE__, :stats)

  @impl true
  def init(_opts) do
    {:ok, %{
      tools_built: [],
      tools_deployed: [],
      total_needs_detected: 0,
      total_tools_built: 0,
      total_tools_deployed: 0,
      total_tools_failed: 0,
      started_at: DateTime.utc_now()
    }}
  end

  @impl true
  def handle_call({:engineer, need}, _from, state) do
    Logger.info("ToolForge: Engineering tool for need: #{need.description}")
    result = run_pipeline(need)
    new_state = case result do
      {:ok, tool} ->
        %{state |
          tools_built: [tool | state.tools_built],
          total_tools_built: state.total_tools_built + 1
        }
      {:error, _} ->
        %{state | total_tools_failed: state.total_tools_failed + 1}
    end
    {:reply, result, new_state}
  end

  @impl true
  def handle_call({:detect_and_engineer, system_state}, _from, state) do
    needs = NeedDetector.detect(system_state)
    if needs == [] do
      {:reply, {:ok, :no_needs_detected}, state}
    else
      top_need = hd(needs)
      Logger.info("ToolForge: Detected #{length(needs)} needs. Engineering top priority: #{top_need.description}")
      result = run_pipeline(top_need)
      new_state = case result do
        {:ok, tool} ->
          %{state |
            tools_built: [tool | state.tools_built],
            total_needs_detected: state.total_needs_detected + length(needs),
            total_tools_built: state.total_tools_built + 1
          }
        {:error, _} ->
          %{state |
            total_needs_detected: state.total_needs_detected + length(needs),
            total_tools_failed: state.total_tools_failed + 1
          }
      end
      {:reply, result, new_state}
    end
  end

  @impl true
  def handle_call(:built_tools, _from, state) do
    {:reply, state.tools_built, state}
  end

  @impl true
  def handle_call(:stats, _from, state) do
    {:reply, %{
      tools_built: state.total_tools_built,
      tools_deployed: state.total_tools_deployed,
      tools_failed: state.total_tools_failed,
      needs_detected: state.total_needs_detected,
      active_tools: length(state.tools_built)
    }, state}
  end

  @impl true
  def handle_info(_, state), do: {:noreply, state}

  defp run_pipeline(%ToolNeed{} = need) do
    with \
      spec <- ToolArchitect.design(need),
      Logger.info("ToolForge: Designed #{spec.name} (#{spec.language})"),
      {:ok, tool} <- ToolBuilder.build(spec),
      Logger.info("ToolForge: Built #{tool.name} (#{map_size(tool.source_files)} files)"),
      :ok <- validate_tool(tool),
      Logger.info("ToolForge: Validated #{tool.name}"),
      :ok <- request_human_review(tool, spec),
      Logger.info("ToolForge: Human review passed for #{tool.name}")
    do
      {:ok, tool}
    else
      {:error, reason} ->
        Logger.warning("ToolForge: Pipeline failed for #{need.description}: #{inspect(reason)}")
        {:error, reason}
    end
  end

  defp validate_tool(%GeneratedTool{} = tool) do
    cond do
      tool.source_files == %{} -> {:error, :no_source_files}
      tool.name == nil -> {:error, :no_name}
      true -> :ok
    end
  end

  defp request_human_review(%GeneratedTool{} = tool, %ToolSpecification{} = spec) do
    try do
      Tiannara.HAI.Domain.ReviewRequest.new(%{
        source_subsystem: :tool_forge,
        decision_type: :tool_deployment,
        summary: "Deploy generated tool: #{tool.name} (#{tool.language})",
        impact_level: :medium,
        confidence: 0.7,
        uncertainty: 0.3
      })
      :ok
    rescue
      _ -> :ok
    end
  end
end
