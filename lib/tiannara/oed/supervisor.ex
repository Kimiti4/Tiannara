defmodule Tiannara.OED.Supervisor do
  @moduledoc "Ontological Evolution & Defense — quarantine, rollback, ACM crucible, OAVL validation"
  use Supervisor
  require Logger

  def start_link(opts \\ []) do
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    children = [
      Tiannara.OED.BudgetController,
      Tiannara.OED.Quarantine.ContradictionTracker,
      Tiannara.OED.Quarantine.SuspendedTheories,
      Tiannara.OED.Quarantine.QuarantineRegistry,
      Tiannara.OED.Rollback.OntologySnapshots,
      Tiannara.OED.Rollback.RollbackController,
      Tiannara.OED.UMSC.StabilityController,
      Tiannara.OED.ACM.CrucibleSupervisor,
      Tiannara.OED.OAVL.ValidationSupervisor
    ]
    Supervisor.init(children, strategy: :one_for_one)
  end
end

defmodule Tiannara.OED.BudgetController do
  use GenServer
  require Logger
  def start_link(opts), do: GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  @impl true
  def init(_) do
    Logger.info("[OED] BudgetController initialized")
    {:ok, %{budget: 1000, allocated: %{}, reserved: 0}}
  end
  def allocate(operation, amount), do: GenServer.call(__MODULE__, {:allocate, operation, amount})
  @impl true
  def handle_call({:allocate, operation, amount}, _from, state) when state.budget - state.reserved >= amount do
    {:reply, :ok, %{state | allocated: Map.put(state.allocated, operation, amount), reserved: state.reserved + amount}}
  end
  def handle_call({:allocate, _operation, _amount}, _from, state), do: {:reply, {:error, :insufficient_budget}, state}
end

defmodule Tiannara.OED.Quarantine.ContradictionTracker do
  use GenServer
  require Logger
  def start_link(opts), do: GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  @impl true
  def init(_) do
    Logger.info("[OED] ContradictionTracker initialized")
    {:ok, %{contradictions: %{}}}
  end
  def record(entity, details), do: GenServer.cast(__MODULE__, {:record, entity, details})
  def count, do: GenServer.call(__MODULE__, :count)
  @impl true
  def handle_cast({:record, entity, details}, state) do
    {:noreply, %{state | contradictions: Map.update(state.contradictions, entity, [details], fn list -> [details | list] end)}}
  end
  @impl true
  def handle_call(:count, _from, state), do: {:reply, map_size(state.contradictions), state}
end

defmodule Tiannara.OED.Quarantine.SuspendedTheories do
  use GenServer
  require Logger
  def start_link(opts), do: GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  @impl true
  def init(_) do
    Logger.info("[OED] SuspendedTheories initialized")
    {:ok, %{suspended: %{}}}
  end
  def suspend(theory_id, reason), do: GenServer.cast(__MODULE__, {:suspend, theory_id, reason})
  def list, do: GenServer.call(__MODULE__, :list)
  @impl true
  def handle_cast({:suspend, id, reason}, state) do
    {:noreply, %{state | suspended: Map.put(state.suspended, id, %{reason: reason, suspended_at: DateTime.utc_now()})}}
  end
  @impl true
  def handle_call(:list, _from, state), do: {:reply, state.suspended, state}
end

defmodule Tiannara.OED.Quarantine.QuarantineRegistry do
  use GenServer
  require Logger
  def start_link(opts), do: GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  @impl true
  def init(_) do
    Logger.info("[OED] QuarantineRegistry initialized")
    {:ok, %{quarantined: %{}}}
  end
  def quarantine(id, reason), do: GenServer.cast(__MODULE__, {:quarantine, id, reason})
  def release(id), do: GenServer.cast(__MODULE__, {:release, id})
  def all, do: GenServer.call(__MODULE__, :all)
  @impl true
  def handle_cast({:quarantine, id, reason}, state) do
    {:noreply, %{state | quarantined: Map.put(state.quarantined, id, %{reason: reason, quarantined_at: DateTime.utc_now()})}}
  end
  def handle_cast({:release, id}, state), do: {:noreply, %{state | quarantined: Map.delete(state.quarantined, id)}}
  @impl true
  def handle_call(:all, _from, state), do: {:reply, state.quarantined, state}
end

defmodule Tiannara.OED.Rollback.OntologySnapshots do
  use GenServer
  require Logger
  def start_link(opts), do: GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  @impl true
  def init(_) do
    Logger.info("[OED] OntologySnapshots initialized")
    {:ok, %{snapshots: %{}, max_snapshots: 50}}
  end
  def snapshot(domain, data), do: GenServer.cast(__MODULE__, {:snapshot, domain, data})
  def get(domain), do: GenServer.call(__MODULE__, {:get, domain})
  @impl true
  def handle_cast({:snapshot, domain, data}, state) do
    existing = Map.get(state.snapshots, domain, [])
    updated = [%{data: data, captured_at: DateTime.utc_now()} | existing] |> Enum.take(state.max_snapshots)
    {:noreply, %{state | snapshots: Map.put(state.snapshots, domain, updated)}}
  end
  @impl true
  def handle_call({:get, domain}, _from, state), do: {:reply, Map.get(state.snapshots, domain, []), state}
end

defmodule Tiannara.OED.Rollback.RollbackController do
  use GenServer
  require Logger
  def start_link(opts), do: GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  @impl true
  def init(_) do
    Logger.info("[OED] RollbackController initialized")
    {:ok, %{rollbacks: [], max_rollbacks: 20}}
  end
  def rollback(domain, to_version), do: GenServer.call(__MODULE__, {:rollback, domain, to_version})
  def history, do: GenServer.call(__MODULE__, :history)
  @impl true
  def handle_call({:rollback, domain, to_version}, _from, state) do
    entry = %{domain: domain, to_version: to_version, rolled_back_at: DateTime.utc_now()}
    {:reply, :ok, %{state | rollbacks: [entry | state.rollbacks] |> Enum.take(state.max_rollbacks)}}
  end
  @impl true
  def handle_call(:history, _from, state), do: {:reply, state.rollbacks, state}
end

defmodule Tiannara.OED.UMSC.StabilityController do
  use GenServer
  require Logger
  def start_link(opts), do: GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  @impl true
  def init(_) do
    Logger.info("[OED] UMSC.StabilityController initialized")
    {:ok, %{stability_score: 1.0, readings: []}}
  end
  def report(score), do: GenServer.cast(__MODULE__, {:report, score})
  def current, do: GenServer.call(__MODULE__, :current)
  @impl true
  def handle_cast({:report, score}, state) do
    {:noreply, %{state | stability_score: score, readings: [score | state.readings] |> Enum.take(100)}}
  end
  @impl true
  def handle_call(:current, _from, state), do: {:reply, state.stability_score, state}
end

defmodule Tiannara.OED.ACM.CrucibleSupervisor do
  use Supervisor
  require Logger
  def start_link(opts), do: Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  @impl true
  def init(_opts) do
    Logger.info("[OED] ACM.CrucibleSupervisor initialized")
    Supervisor.init([], strategy: :one_for_one)
  end
end

defmodule Tiannara.OED.OAVL.ValidationSupervisor do
  use Supervisor
  require Logger
  def start_link(opts), do: Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  @impl true
  def init(_opts) do
    Logger.info("[OED] OAVL.ValidationSupervisor initialized")
    Supervisor.init([], strategy: :one_for_one)
  end
end
