defmodule Tiannara.REA.ResearchEconomy do
  use GenServer

  def start_link(opts \\ []), do: GenServer.start_link(__MODULE__, opts, name: __MODULE__)

  # --- PUBLIC API ---

  def get_state do
    GenServer.call(__MODULE__, :get_state)
  end

  def grant_credits(amount) do
    GenServer.call(__MODULE__, {:grant_credits, amount})
  end

  def deduct_credits(amount) do
    GenServer.call(__MODULE__, {:deduct_credits, amount})
  end

  def allocate_resources(allocations) do
    GenServer.call(__MODULE__, {:allocate_resources, allocations})
  end

  def spend_resources(compute_cost, attention_cost) do
    GenServer.call(__MODULE__, {:spend_resources, compute_cost, attention_cost})
  end

  def tick do
    GenServer.call(__MODULE__, :tick)
  end

  def reset do
    GenServer.call(__MODULE__, :reset)
  end

  # --- CALLBACKS ---

  @impl true
  def init(_opts) do
    {:ok, %{
      credits: 1000.0,
      compute: 100.0,
      attention: 100.0,
      time: 0.0,
      allocations: %{} # institution_id => %{compute_share: float, attention_share: float}
    }}
  end

  @impl true
  def handle_call(:get_state, _from, state) do
    {:reply, state, state}
  end

  @impl true
  def handle_call(:tick, _from, state) do
    # Regrow resources to baseline max of 100.0
    new_state = %{
      state |
      compute: 100.0,
      attention: 100.0,
      time: state.time + 1.0
    }
    {:reply, :ok, new_state}
  end

  @impl true
  def handle_call({:grant_credits, amount}, _from, state) do
    new_state = %{state | credits: state.credits + amount}
    {:reply, :ok, new_state}
  end

  @impl true
  def handle_call({:deduct_credits, amount}, _from, state) do
    new_state = %{state | credits: max(0.0, state.credits - amount)}
    {:reply, :ok, new_state}
  end

  @impl true
  def handle_call({:allocate_resources, allocations}, _from, state) do
    new_state = %{state | allocations: allocations}
    {:reply, :ok, new_state}
  end

  @impl true
  def handle_call({:spend_resources, compute_cost, attention_cost}, _from, state) do
    if state.compute >= compute_cost and state.attention >= attention_cost do
      new_state = %{
        state |
        compute: Float.round(state.compute - compute_cost, 4),
        attention: Float.round(state.attention - attention_cost, 4),
        time: state.time + 1.0
      }
      {:reply, :ok, new_state}
    else
      {:reply, {:error, :insufficient_resources}, state}
    end
  end

  @impl true
  def handle_call(:reset, _from, _state) do
    {:reply, :ok, %{
      credits: 1000.0,
      compute: 100.0,
      attention: 100.0,
      time: 0.0,
      allocations: %{}
    }}
  end
end
