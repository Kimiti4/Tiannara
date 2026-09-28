defmodule Tiannara.CEL.Planner do
  @moduledoc """
  Deterministic constitutional task planner.

  Converts a natural-language objective into a bounded execution plan. This is
  intentionally not an LLM and does not claim general intelligence; it provides
  a reliable planning substrate for the higher-level Jarvis runtime.
  """
  use GenServer

  @max_steps 12

  def start_link(_opts), do: GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  def healthy?, do: GenServer.call(__MODULE__, :healthy)
  def constitutional_score, do: GenServer.call(__MODULE__, :constitutional_score)
  def plan(objective), do: GenServer.call(__MODULE__, {:plan, objective})

  @impl true
  def init(_opts), do: {:ok, %{plans: 0}}

  @impl true
  def handle_call(:healthy, _from, state), do: {:reply, true, state}
  @impl true
  def handle_call(:constitutional_score, _from, state) do
    {:reply, Tiannara.CEL.Kernel.ConstitutionalScore.default(:executive_planner), state}
  end

  @impl true
  def handle_call({:plan, objective}, _from, state) when is_binary(objective) do
    plan = build_plan(objective)
    {:reply, {:ok, plan}, %{state | plans: state.plans + 1}}
  end
  def handle_call({:plan, _}, _from, state), do: {:reply, {:error, :invalid_objective}, state}

  defp build_plan(objective) do
    lower = String.downcase(objective)
    steps = []
    steps = if contains_any?(lower, ["research", "investigate", "analyze", "audit"]), do: steps ++ [:research], else: steps
    steps = if contains_any?(lower, ["design", "architect", "build", "implement", "code"]), do: steps ++ [:design], else: steps
    steps = if contains_any?(lower, ["test", "verify", "validate", "prove"]), do: steps ++ [:verification], else: steps
    steps = if contains_any?(lower, ["deploy", "release", "apply"]), do: steps ++ [:deployment_gate], else: steps
    steps = if steps == [], do: [:clarify, :analyze, :propose, :verify], else: steps
    steps = Enum.take(Enum.uniq(steps ++ [:evidence_report]), @max_steps)

    %{objective: objective, steps: steps, bounded: true, requires_human_gate: :deployment_gate in steps,
      generated_at: DateTime.utc_now(), planner: __MODULE__}
  end

  defp contains_any?(text, terms), do: Enum.any?(terms, &String.contains?(text, &1))
end
