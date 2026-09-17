defmodule Tiannara.OED.BudgetController do
  @moduledoc """
  🛡️ OED Budget Controller.

  Tracks, updates, and enforces execution budgets (VRAM, branch count,
  active simulations, and active threads) across the OED and OPC layers.
  """

  use GenServer
  require Logger

  # State structure
  defstruct [
    vram_used: 0.0,
    branch_count: 0,
    active_simulations: 0,
    max_vram: 8192.0,      # Max mock VRAM in MB
    max_branches: 100,      # Max active timeline forks
    max_simulations: 10     # Max parallel simulation workers
  ]

  # ==================== Public API ====================

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc """
  Queries the current resource budgets state.
  """
  @spec current_usage() :: map()
  def current_usage do
    GenServer.call(__MODULE__, :current_usage)
  end

  @doc """
  Attempts to allocate the specified resource block.
  Returns `:ok` or `{:error, reason}` if thresholds are breached.
  """
  @spec allocate(type :: :vram | :branch | :simulation, amount :: number()) :: :ok | {:error, String.t()}
  def allocate(type, amount \\ 1) do
    GenServer.call(__MODULE__, {:allocate, type, amount})
  end

  @doc """
  Releases previously allocated resources.
  """
  @spec release(type :: :vram | :branch | :simulation, amount :: number()) :: :ok
  def release(type, amount \\ 1) do
    GenServer.cast(__MODULE__, {:release, type, amount})
  end

  # ==================== GenServer Callbacks ====================

  @impl true
  def init(opts) do
    state = %__MODULE__{
      max_vram: Keyword.get(opts, :max_vram, 8192.0),
      max_branches: Keyword.get(opts, :max_branches, 100),
      max_simulations: Keyword.get(opts, :max_simulations, 10)
    }

    Logger.info("🛡️ [OED Budget] Controller initialized (VRAM cap: #{state.max_vram}MB, Branch cap: #{state.max_branches})")
    {:ok, state}
  end

  @impl true
  def handle_call(:current_usage, _from, state) do
    usage = %{
      vram_used: state.vram_used,
      branch_count: state.branch_count,
      active_simulations: state.active_simulations,
      vram_available: state.max_vram - state.vram_used,
      branch_available: state.max_branches - state.branch_count,
      simulation_available: state.max_simulations - state.active_simulations
    }
    {:reply, usage, state}
  end

  @impl true
  def handle_call({:allocate, :vram, amount}, _from, state) do
    if state.vram_used + amount <= state.max_vram do
      new_state = %{state | vram_used: state.vram_used + amount}
      {:reply, :ok, new_state}
    else
      {:reply, {:error, "VRAM allocation limit reached"}, state}
    end
  end

  def handle_call({:allocate, :branch, amount}, _from, state) do
    if state.branch_count + amount <= state.max_branches do
      new_state = %{state | branch_count: state.branch_count + amount}
      {:reply, :ok, new_state}
    else
      {:reply, {:error, "Timeline branch allocation limit reached"}, state}
    end
  end

  def handle_call({:allocate, :simulation, amount}, _from, state) do
    if state.active_simulations + amount <= state.max_simulations do
      new_state = %{state | active_simulations: state.active_simulations + amount}
      {:reply, :ok, new_state}
    else
      {:reply, {:error, "Parallel simulation limit reached"}, state}
    end
  end

  @impl true
  def handle_cast({:release, :vram, amount}, state) do
    new_vram = max(0.0, state.vram_used - amount)
    {:noreply, %{state | vram_used: new_vram}}
  end

  def handle_cast({:release, :branch, amount}, state) do
    new_branches = max(0, state.branch_count - amount)
    {:noreply, %{state | branch_count: new_branches}}
  end

  def handle_cast({:release, :simulation, amount}, state) do
    new_sims = max(0, state.active_simulations - amount)
    {:noreply, %{state | active_simulations: new_sims}}
  end
end
