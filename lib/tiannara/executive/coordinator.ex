defmodule Tiannara.Executive.Coordinator do
  @moduledoc """
  Executive coordination protocol for the Executive Memory subsystem.

  Receives commands, evaluates them via consensus, executes them
  through ExecutiveMemory, and publishes outcome events.
  """

  use GenServer

  require Logger

  alias Tiannara.Executive.{Command, Event, Consensus}

  defstruct [:name, :plans, :metrics]

  @type t :: %__MODULE__{
    name: atom(),
    plans: %{String.t() => Command.t()},
    metrics: map()
  }

  @doc "Starts the Coordinator GenServer."
  def start_link(opts \\ []) do
    name = Keyword.get(opts, :name, __MODULE__)
    GenServer.start_link(__MODULE__, name, name: name)
  end

  @doc "Submits a command for execution."
  def submit(command), do: GenServer.call(__MODULE__, {:submit, command})

  @doc "Returns the status of a submitted command/plan."
  def plan_status(command_id), do: GenServer.call(__MODULE__, {:status, command_id})

  @doc "Cancels a pending command/plan."
  def cancel_plan(command_id), do: GenServer.call(__MODULE__, {:cancel, command_id})

  @doc "Returns coordinator metrics."
  def metrics, do: GenServer.call(__MODULE__, :metrics)

  @impl true
  def init(name) do
    Logger.info("[ExecutiveMemory.Coordinator] Started: #{name}")
    {:ok, %__MODULE__{name: name, plans: %{}, metrics: %{submitted: 0, approved: 0, rejected: 0, executed: 0, failed: 0}}}
  end

  @impl true
  def handle_call({:submit, %Command{} = cmd}, _from, state) do
    state = put_in(state.metrics[:submitted], state.metrics[:submitted] + 1)
    state = put_in(state.plans[cmd.id], cmd)

    {outcome, state} =
      case Consensus.evaluate(cmd, :simple) do
        :approved ->
          approved = Command.approve(cmd)
          state = put_in(state.plans[cmd.id], approved)
          state = put_in(state.metrics[:approved], state.metrics[:approved] + 1)
          execute_command(approved)
          state = put_in(state.metrics[:executed], state.metrics[:executed] + 1)
          event = Event.new("command.executed", %{command_id: cmd.id, action: cmd.action, result: :ok})
          Tiannara.Executive.EventBus.publish(event)
          {:ok, state}

        {:error, reason} ->
          rejected = Command.reject(cmd, reason)
          state = put_in(state.plans[cmd.id], rejected)
          state = put_in(state.metrics[:rejected], state.metrics[:rejected] + 1)
          {{:error, reason}, state}
      end

    {:reply, outcome, state}
  end

  @impl true
  def handle_call({:status, command_id}, _from, state) do
    case Map.get(state.plans, command_id) do
      nil -> {:reply, {:error, :not_found}, state}
      cmd -> {:reply, {:ok, cmd.status}, state}
    end
  end

  @impl true
  def handle_call({:cancel, command_id}, _from, state) do
    case Map.get(state.plans, command_id) do
      nil -> {:reply, {:error, :not_found}, state}
      %Command{status: :pending} = cmd ->
        cancelled = Command.reject(cmd, "cancelled")
        state = put_in(state.plans[command_id], cancelled)
        {:reply, :ok, state}
      _ -> {:reply, {:error, :already_processed}, state}
    end
  end

  @impl true
  def handle_call(:metrics, _from, state) do
    {:reply, state.metrics, state}
  end

  defp execute_command(%Command{action: action, arguments: args}) do
    case action do
      :put -> Tiannara.Executive.ExecutiveMemory.put(args.key, args.value, Map.get(args, :attrs, %{}))
      :delete -> Tiannara.Executive.ExecutiveMemory.delete(args.key)
      :flush -> Tiannara.Executive.ExecutiveMemory.flush()
      :compact -> Tiannara.Executive.ExecutiveMemory.compact()
      :gc -> Tiannara.Executive.ExecutiveMemory.gc()
      _ -> {:error, :unknown_action}
    end
  end
end
