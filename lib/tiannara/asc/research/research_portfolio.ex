defmodule Tiannara.ASC.Research.Portfolio do
  use GenServer

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def record_outcome(program_id, outcome) do
    GenServer.cast(__MODULE__, {:record_outcome, program_id, outcome})
  end

  def summary, do: GenServer.call(__MODULE__, :summary)

  def domain_roi(domain), do: GenServer.call(__MODULE__, {:domain_roi, domain})

  def success_rate, do: GenServer.call(__MODULE__, :success_rate)

  @impl true
  def init(_opts) do
    {:ok, %{
      outcomes: [],
      domain_stats: %{},
      total_invested: 0,
      total_returned: 0,
      successes: 0,
      failures: 0,
      started_at: DateTime.utc_now()
    }}
  end

  @impl true
  def handle_cast({:record_outcome, program_id, outcome}, state) do
    entry = %{
      program_id: program_id,
      outcome: outcome,
      domain: Map.get(outcome, :domain, :general),
      success: Map.get(outcome, :success, false),
      impact: Map.get(outcome, :impact, 0.0),
      resources_used: Map.get(outcome, :resources_used, 0),
      at: DateTime.utc_now()
    }

    domain = entry.domain
    domain_stat = Map.get(state.domain_stats, domain, %{successes: 0, failures: 0, total_impact: 0.0})

    domain_stat = %{domain_stat |
      successes: domain_stat.successes + if(entry.success, do: 1, else: 0),
      failures: domain_stat.failures + if(entry.success, do: 0, else: 1),
      total_impact: domain_stat.total_impact + entry.impact
    }

    {:noreply, %{state |
      outcomes: [entry | state.outcomes] |> Enum.take(1000),
      domain_stats: Map.put(state.domain_stats, domain, domain_stat),
      successes: state.successes + if(entry.success, do: 1, else: 0),
      failures: state.failures + if(entry.success, do: 0, else: 1),
      total_invested: state.total_invested + entry.resources_used,
      total_returned: state.total_returned + entry.impact
    }}
  end

  @impl true
  def handle_call(:summary, _from, state) do
    total = state.successes + state.failures

    {:reply, %{
      total_programs: total,
      successes: state.successes,
      failures: state.failures,
      success_rate: if(total > 0, do: state.successes / total, else: 0.0),
      total_invested: state.total_invested,
      total_returned: state.total_returned,
      roi: if(state.total_invested > 0, do: state.total_returned / state.total_invested, else: 0.0),
      domains: map_size(state.domain_stats)
    }, state}
  end

  @impl true
  def handle_call({:domain_roi, domain}, _from, state) do
    case Map.fetch(state.domain_stats, domain) do
      {:ok, stat} ->
        total = stat.successes + stat.failures
        roi = %{
          domain: domain,
          successes: stat.successes,
          failures: stat.failures,
          success_rate: if(total > 0, do: stat.successes / total, else: 0.0),
          total_impact: stat.total_impact
        }
        {:reply, {:ok, roi}, state}

      :error ->
        {:reply, {:error, :unknown_domain}, state}
    end
  end

  @impl true
  def handle_call(:success_rate, _from, state) do
    total = state.successes + state.failures
    rate = if(total > 0, do: state.successes / total, else: 0.0)
    {:reply, rate, state}
  end

  @impl true
  def handle_info(_, state), do: {:noreply, state}
end
