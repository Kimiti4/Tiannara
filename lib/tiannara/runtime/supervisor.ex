defmodule Tiannara.Runtime.Supervisor do
  @moduledoc """
  Live runtime wiring: supervises the epistemic event bus, the graph, the Ω.1
  Sentinel heartbeat, the constitutional monitor, and the Ω-layer integration
  loop — with heartbeat, monitor, and Ω-loop all connected through the bus.

  This is the autonomous-but-gated living loop. It observes, proposes, and
  reports; it does not act (augmentation clause).

  Constitutional basis: Fault tolerance, "Detect anomalies / degraded
  performance", "Maintain audit trails", "Capability must never outpace
  verification", augmentation clause.
  """
  use Supervisor

  alias Tiannara.Runtime.EventBus

  def start_link(opts \\ []) do
    name = Keyword.get(opts, :name, __MODULE__)
    Supervisor.start_link(__MODULE__, opts, name: name)
  end

  @doc "Stop the runtime supervisor tree (test/teardown helper)."
  def stop(sup, reason \\ :normal) do
    Supervisor.stop(sup, reason)
  end

  @impl true
  def init(opts) do
    bus_name = Keyword.get(opts, :bus_name, Tiannara.Runtime.EventBus)
    emitter = fn event -> EventBus.publish(bus_name, event) end

    children =
      [{EventBus, [name: bus_name]}] ++
        graph_child(opts) ++
        heartbeat_child(opts, emitter) ++
        monitor_child(opts, emitter) ++
        omega_child(opts, bus_name)

    Supervisor.init(children, strategy: :one_for_one)
  end

  defp graph_child(opts) do
    case Keyword.get(opts, :graph) do
      nil -> []
      {mod, gopts} -> [{mod, gopts}]
    end
  end

  defp heartbeat_child(opts, emitter) do
    case Keyword.get(opts, :heartbeat) do
      nil -> []
      hb -> [{Tiannara.Sentinel.Heartbeat.Server, Keyword.put(hb, :emitter, emitter)}]
    end
  end

  defp monitor_child(opts, emitter) do
    case Keyword.get(opts, :monitor) do
      nil -> []
      mon -> [{Tiannara.Constitution.Runtime.Monitor, Keyword.put_new(mon, :publisher, emitter)}]
    end
  end

  defp omega_child(opts, bus_name) do
    case Keyword.get(opts, :omega) do
      nil -> []
      omega_opts -> [{Tiannara.Omega.Loop, Keyword.put(omega_opts, :bus, bus_name)}]
    end
  end
end