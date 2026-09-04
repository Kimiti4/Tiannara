defmodule Tiannara.ValidationCampaigns do
  use GenServer
  require Logger

  alias Tiannara.CEL.Services.ExecutiveMemory

  @max_history 100

  def start_link(_opts), do: GenServer.start_link(__MODULE__, %{}, name: __MODULE__)

  def start_campaign(campaign_config) do
    GenServer.call(__MODULE__, {:start_campaign, campaign_config})
  end

  def run_campaign(campaign_id) do
    GenServer.call(__MODULE__, {:run_campaign, campaign_id}, :timer.minutes(5))
  end

  def get_campaign(campaign_id) do
    GenServer.call(__MODULE__, {:get_campaign, campaign_id})
  end

  def list_campaigns(status \\ nil) do
    GenServer.call(__MODULE__, {:list_campaigns, status})
  end

  def report(campaign_id) do
    GenServer.call(__MODULE__, {:report, campaign_id})
  end

  @impl true
  def init(_opts) do
    {:ok, %{
      campaigns: %{},
      campaign_order: [],
      healthy: true,
      started_at: DateTime.utc_now()
    }}
  end

  @impl true
  def handle_call({:start_campaign, config}, _from, state) do
    campaign_id = Map.get(config, :id, "campaign_#{:crypto.strong_rand_bytes(6) |> Base.encode16(case: :lower)}")

    campaign = %{
      id: campaign_id,
      name: Map.get(config, :name, "Unnamed Campaign"),
      description: Map.get(config, :description, ""),
      target_modules: Map.get(config, :target_modules, []),
      scenarios: Map.get(config, :scenarios, []),
      status: :defined,
      results: [],
      metrics: %{},
      passed: 0,
      failed: 0,
      total: 0,
      started_at: DateTime.utc_now(),
      completed_at: nil
    }

    Logger.info("ValidationCampaigns: campaign #{campaign_id} defined (#{campaign.name})")

    ExecutiveMemory.record_decision(
      "campaign_defined_#{campaign_id}",
      :validation_campaign_defined,
      %{campaign_id: campaign_id, name: campaign.name, scenario_count: length(campaign.scenarios)}
    )

    new_campaigns = Map.put(state.campaigns, campaign_id, campaign)
    new_order = [campaign_id | state.campaign_order] |> Enum.take(@max_history)

    {:reply, {:ok, campaign_id}, %{state | campaigns: new_campaigns, campaign_order: new_order}}
  end

  @impl true
  def handle_call({:run_campaign, campaign_id}, _from, state) do
    case Map.fetch(state.campaigns, campaign_id) do
      {:ok, campaign} ->
        running = %{campaign | status: :running}
        results = Enum.map(campaign.scenarios, &execute_scenario/1)
        passed = Enum.count(results, &(&1.status == :pass))
        failed = Enum.count(results, &(&1.status == :fail))

        completed = %{running |
          status: :completed,
          results: results,
          passed: passed,
          failed: failed,
          total: length(results),
          completed_at: DateTime.utc_now()
        }

        Logger.info("ValidationCampaigns: campaign #{campaign_id} completed — #{passed}/#{length(results)} passed")

        ExecutiveMemory.record_decision(
          "campaign_completed_#{campaign_id}",
          :validation_campaign_completed,
          %{campaign_id: campaign_id, passed: passed, failed: failed, total: length(results)}
        )

        new_campaigns = Map.put(state.campaigns, campaign_id, completed)
        {:reply, {:ok, completed}, %{state | campaigns: new_campaigns}}

      :error ->
        {:reply, {:error, :campaign_not_found}, state}
    end
  end

  @impl true
  def handle_call({:get_campaign, campaign_id}, _from, state) do
    case Map.fetch(state.campaigns, campaign_id) do
      {:ok, campaign} -> {:reply, {:ok, campaign}, state}
      :error -> {:reply, {:error, :not_found}, state}
    end
  end

  @impl true
  def handle_call({:list_campaigns, status_filter}, _from, state) do
    result =
      state.campaign_order
      |> Enum.map(&Map.get(state.campaigns, &1))
      |> Enum.reject(&is_nil/1)
      |> then(fn list ->
        case status_filter do
          nil -> list
          s -> Enum.filter(list, &(&1.status == s))
        end
      end)

    {:reply, {:ok, result}, state}
  end

  @impl true
  def handle_call({:report, campaign_id}, _from, state) do
    case Map.fetch(state.campaigns, campaign_id) do
      {:ok, campaign} ->
        pass_rate = if campaign.total > 0, do: campaign.passed / campaign.total, else: 1.0

        report = %{
          campaign_id: campaign.id,
          name: campaign.name,
          status: campaign.status,
          summary: "#{campaign.passed}/#{campaign.total} scenarios passed",
          pass_rate: pass_rate,
          failures: Enum.filter(campaign.results, &(&1.status == :fail)),
          started_at: campaign.started_at,
          completed_at: campaign.completed_at
        }
        {:reply, {:ok, report}, state}

      :error ->
        {:reply, {:error, :not_found}, state}
    end
  end

  defp execute_scenario(scenario) do
    module = scenario.module
    function = scenario.function
    args = Map.get(scenario, :args, [])

    start = System.monotonic_time(:millisecond)

    try do
      result = apply(module, function, args)
      duration = System.monotonic_time(:millisecond) - start

      case result do
        {:ok, _} ->
          %{scenario: scenario.name, status: :pass, duration_ms: duration, details: result}

        {:error, reason} ->
          %{scenario: scenario.name, status: :fail, duration_ms: duration, error: reason}
      end
    rescue
      e ->
        duration = System.monotonic_time(:millisecond) - start
        %{scenario: scenario.name, status: :fail, duration_ms: duration, error: {:exception, e}}
    end
  end
end
