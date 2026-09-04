defmodule Tiannara.Council.PrincipleRegistry do
  use GenServer
  require Logger

  @moduledoc """
  Principle Registry — dynamic manager of constitutional principle plugins.

  Allows principles to be registered, deprecated, or queried at runtime
  without modifying the core RuleEngine.
  """

  def start_link(_opts), do: GenServer.start_link(__MODULE__, %{}, name: __MODULE__)

  def register_principle(module) do
    GenServer.call(__MODULE__, {:register, module})
  end

  def deprecate_principle(principle_id) do
    GenServer.call(__MODULE__, {:deprecate, principle_id})
  end

  def active_principles, do: GenServer.call(__MODULE__, :active)

  def evaluate_all(decision_type, payload, context) do
    GenServer.call(__MODULE__, {:evaluate_all, decision_type, payload, context})
  end

  @impl true
  def init(_opts) do
    default = [
      Tiannara.Council.Principles.EvidenceBeforeConfidence,
      Tiannara.Council.Principles.VerificationFirst
    ]

    principles =
      Map.new(default, fn mod ->
        {mod.id(), %{module: mod, deprecated: false}}
      end)

    Logger.info("PrincipleRegistry: initialized with #{map_size(principles)} principles")
    {:ok, %{principles: principles}}
  end

  @impl true
  def handle_call({:register, module}, _from, state) do
    id = module.id()
    if Map.has_key?(state.principles, id) do
      {:reply, {:error, :already_registered}, state}
    else
      Logger.info("PrincipleRegistry: registered #{id} v#{module.version()}")
      {:reply, :ok, put_in(state, [:principles, id], %{module: module, deprecated: false})}
    end
  end

  @impl true
  def handle_call({:deprecate, id}, _from, state) do
    if Map.has_key?(state.principles, id) do
      {:reply, :ok, put_in(state, [:principles, id, :deprecated], true)}
    else
      {:reply, {:error, :not_found}, state}
    end
  end

  @impl true
  def handle_call(:active, _from, state) do
    active =
      state.principles
      |> Map.values()
      |> Enum.reject(& &1.deprecated)
      |> Enum.map(& &1.module)

    {:reply, active, state}
  end

  @impl true
  def handle_call({:evaluate_all, decision_type, payload, context}, _from, state) do
    results =
      state.principles
      |> Map.values()
      |> Enum.reject(& &1.deprecated)
      |> Enum.map(fn %{module: mod} -> mod.evaluate(decision_type, payload, context) end)

    {:reply, results, state}
  end
end
