defmodule TelemetryGateway.DomainRouter do
  use GenServer

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def register(domain_prefix, handler_module) do
    GenServer.cast(__MODULE__, {:register, domain_prefix, handler_module})
  end

  def route(event) do
    GenServer.cast(__MODULE__, {:route, event})
  end

  def registered_handlers do
    GenServer.call(__MODULE__, :handlers)
  end

  @impl true
  def init(_opts) do
    handlers = %{
      "runtime" => TelemetryGateway.Handler.RuntimeHandler,
      "scientific" => TelemetryGateway.Handler.ScienceHandler,
      "engineering" => TelemetryGateway.Handler.EngineeringHandler,
      "knowledge" => TelemetryGateway.Handler.EngineeringHandler,
      "planetary" => TelemetryGateway.Handler.PlanetaryHandler,
      "certification" => TelemetryGateway.Handler.CertificationHandler,
      "evolution" => TelemetryGateway.Handler.EvolutionHandler,
      "discovery" => TelemetryGateway.Handler.DiscoveryHandler,
      "governance" => TelemetryGateway.Handler.EngineeringHandler,
      "security" => TelemetryGateway.Handler.EngineeringHandler,
      "infrastructure" => TelemetryGateway.Handler.EngineeringHandler,
      "economics" => TelemetryGateway.Handler.EngineeringHandler,
      "simulation" => TelemetryGateway.Handler.EngineeringHandler,
      "experiment" => TelemetryGateway.Handler.ScienceHandler,
      "operator" => TelemetryGateway.Handler.EngineeringHandler,
      "audit" => TelemetryGateway.Handler.EngineeringHandler,
      "replay" => TelemetryGateway.Handler.EngineeringHandler,
      "alert" => TelemetryGateway.Handler.EngineeringHandler,
      "prediction" => TelemetryGateway.Handler.ScienceHandler,
      "research" => TelemetryGateway.Handler.ScienceHandler
    }

    {:ok, %{handlers: handlers, routed: 0}}
  end

  @impl true
  def handle_cast({:register, prefix, mod}, %{handlers: h} = state) do
    {:noreply, %{state | handlers: Map.put(h, prefix, mod)}}
  end

  @impl true
  def handle_cast({:route, event}, %{handlers: handlers, routed: r} = state) do
    domain = event[:domain] || event.domain || ""
    prefix = domain |> String.split("/") |> List.first()

    case Map.get(handlers, prefix) do
      nil ->
        TelemetryGateway.DeadLetterQueue.enqueue(event, :no_handler_for_domain, domain)

      handler_mod ->
        handler_mod.handle(event)
    end

    {:noreply, %{state | routed: r + 1}}
  end

  @impl true
  def handle_call(:handlers, _from, %{handlers: h} = state) do
    {:reply, h, state}
  end
end
