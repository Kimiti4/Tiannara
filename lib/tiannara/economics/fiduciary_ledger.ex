defmodule Tiannara.Economics.FiduciaryLedger do
  @moduledoc """
  Phase 20: Translates Civilizational Action into Real-World Economics.
  Tracks AWS spend, LLM token costs, Human-in-the-loop hours, vs. Stripe MRR.
  """
  use GenServer
  require Logger

  # Real-world cost mappings
  @cost_per_llm_token 0.00003
  @cost_per_human_review 15.00

  def start_link(_opts), do: GenServer.start_link(__MODULE__, %{treasury: 10_000.0, revenue: 0.0}, name: __MODULE__)

  def init(args), do: {:ok, args}

  def record_infrastructure_cost(_provider, amount_usd) do
    GenServer.call(__MODULE__, {:direct_cost, amount_usd, "Infrastructure"})
  end

  def record_inference_cost(_model, tokens) do
    cost = tokens * @cost_per_llm_token
    GenServer.call(__MODULE__, {:direct_cost, cost, "LLM Inference"})
  end

  def record_human_cost(hours) do
    cost = hours * @cost_per_human_review
    GenServer.call(__MODULE__, {:direct_cost, cost, "Human-in-the-loop"})
  end

  def record_revenue(source, amount_usd) do
    GenServer.call(__MODULE__, {:revenue, source, amount_usd})
  end

  def get_net_income, do: GenServer.call(__MODULE__, :net_income)

  # Handlers
  def handle_call({:direct_cost, amount, description}, _from, state) do
    Logger.info("💸 [FiduciaryLedger] Deducted $#{Float.round(amount, 4)} for #{description}.")
    {:reply, :ok, %{state | treasury: state.treasury - amount}}
  end

  def handle_call({:revenue, source, amount}, _from, state) do
    Logger.info("💰 [FiduciaryLedger] Recognized $#{Float.round(amount, 2)} revenue from #{source}.")
    {:reply, :ok, %{state | revenue: state.revenue + amount}}
  end

  def handle_call(:net_income, _from, state) do
    net = state.revenue - (10_000.0 - state.treasury) # Revenue - Spend
    {:reply, net, state}
  end
  
  def calculate_civilizational_roi(_treaty_id) do
    # Placeholder for calculating the specific ROI of a single treaty
    :ok
  end
end
