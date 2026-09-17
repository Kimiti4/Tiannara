defmodule Tiannara.Infrastructure.Supervisor do
  use Supervisor
  def start_link(init_arg), do: Supervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  def init(_init_arg) do
    children = [
      {Registry, keys: :duplicate, name: Tiannara.EventRegistry}
    ]
    Supervisor.init(children, strategy: :one_for_one)
  end
end

defmodule Tiannara.Governance.Supervisor do
  use Supervisor
  def start_link(init_arg), do: Supervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  def init(_init_arg) do
    children = [
      Tiannara.Infrastructure.Supervisor,
      Tiannara.Telemetry.Supervisor,
      Tiannara.A10.Supervisor
    ]
    Supervisor.init(children, strategy: :rest_for_one)
  end
end

defmodule Tiannara.MSCL.Supervisor do
  use GenServer

  def start_link(init_arg \\ []) do
    GenServer.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  def get_state do
    GenServer.call(__MODULE__, :get_state)
  end

  def register_node(node_id, pressure \\ 0.0) do
    GenServer.call(__MODULE__, {:register_node, node_id, pressure})
  end

  def unregister_node(node_id) do
    GenServer.call(__MODULE__, {:unregister_node, node_id})
  end

  def report_pressure(node_id, pressure) do
    GenServer.call(__MODULE__, {:report_pressure, node_id, pressure})
  end

  def init(_init_arg) do
    {:ok, %{active_nodes: %{}, global_pressure: 0.0, collapse_risk: 0.0,
            max_global_pressure: 10000.0, critical_collapse_risk: 0.85, warning_collapse_risk: 0.70}}
  end

  def handle_call(:get_state, _from, state) do
    {:reply, {:ok, state}, state}
  end

  def handle_call({:register_node, node_id, pressure}, _from, state) do
    nodes = Map.put(state.active_nodes, node_id, pressure)
    {:reply, :ok, %{state | active_nodes: nodes}}
  end

  def handle_call({:unregister_node, node_id}, _from, state) do
    {:reply, :ok, %{state | active_nodes: Map.delete(state.active_nodes, node_id)}}
  end

  def handle_call({:report_pressure, node_id, pressure}, _from, state) do
    nodes = Map.put(state.active_nodes, node_id, pressure)
    values = Map.values(nodes)
    avg = if values == [], do: 0.0, else: Enum.sum(values) / length(values)
    cr = min(avg / max(state.max_global_pressure, 1.0), 1.0)
    {:reply, :ok, %{state | active_nodes: nodes, global_pressure: avg, collapse_risk: cr}}
  end

  def handle_cast({:update_thresholds, max_p, critical, warning}, state) do
    {:noreply, %{state | max_global_pressure: max_p, critical_collapse_risk: critical, warning_collapse_risk: warning}}
  end

  def handle_cast(_, state), do: {:noreply, state}
end

defmodule Tiannara.MSCL.AdaptiveController do
  use GenServer

  def start_link(_) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def init(_) do
    Process.send_after(self(), :tick, 100)
    {:ok, %{tick: 0}}
  end

  def handle_info(:tick, state) do
    tick = state.tick + 1
    k = :math.sin(tick * 0.1) * 1000 + 10000
    GenServer.cast(Tiannara.MSCL.Supervisor, {:update_thresholds, k, 0.8, 0.6})
    Process.send_after(self(), :tick, 100)
    {:noreply, %{state | tick: tick}}
  end
end

defmodule Tiannara.OLEF.Supervisor do
  use Supervisor
  def start_link(init_arg), do: Supervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  def init(_init_arg) do
    children = [
      Tiannara.OLEF.PressureSolver,
      Tiannara.OLEF.GradientRouter
    ]
    Supervisor.init(children, strategy: :rest_for_one)
  end
end

defmodule Tiannara.CIS.Supervisor do
  use Supervisor
  def start_link(init_arg), do: Supervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  def init(_init_arg) do
    children = [
      Tiannara.CIS.CollapsePredictor,
      Tiannara.CIS.ImmuneDecisionEngine,
      Tiannara.CIS.RegulationExecutor
    ]
    Supervisor.init(children, strategy: :one_for_one)
  end
end

defmodule Tiannara.P9X.Supervisor do
  use Supervisor
  def start_link(init_arg), do: Supervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  def init(_init_arg) do
    children = [
      Tiannara.P9X.ObserverFreeCoherence,
      Tiannara.P9X.ClosureStabilityAudit,
      Tiannara.P9X.GenesisLoopValidator
    ]
    Supervisor.init(children, strategy: :rest_for_one)
  end
end

defmodule Tiannara.GRCC.Supervisor do
  use Supervisor
  def start_link(init_arg), do: Supervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  def init(_init_arg) do
    children = [
      Tiannara.GRCC.IdentityField,
      Tiannara.GRCC.LineageManager,
      Tiannara.GRCC.EntropyController
    ]
    Supervisor.init(children, strategy: :rest_for_one)
  end
end

defmodule Tiannara.Telemetry.Supervisor do
  use Supervisor
  def start_link(init_arg), do: Supervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  def init(_init_arg) do
    children = [
      Tiannara.Telemetry.EventAggregator
    ]
    Supervisor.init(children, strategy: :one_for_one)
  end
end

defmodule Tiannara.P9XEcosystem.Supervisor do
  use Supervisor
  @moduledoc """
  The top-level supervisor for the P9X Ecological Governance Substrate.
  Boots Infrastructure first, then Telemetry, then the MSCL constraints,
  and lastly the ecological layers.
  """
  def start_link(init_arg), do: Supervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  def init(_init_arg) do
    children = [
      Tiannara.Governance.Supervisor,
      Tiannara.MSCL.Supervisor,
      Tiannara.OLEF.Supervisor,
      Tiannara.CIS.Supervisor,
      Tiannara.P9X.Supervisor,
      Tiannara.GRCC.Supervisor
    ]
    Supervisor.init(children, strategy: :rest_for_one)
  end
end
