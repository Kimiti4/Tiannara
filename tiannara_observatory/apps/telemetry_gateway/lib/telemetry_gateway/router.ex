defmodule TelemetryGateway.Router do
  use GenServer

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def route(event) do
    GenServer.cast(__MODULE__, {:route, event})
  end

  @impl true
  def init(_opts) do
    {:ok, %{routed: 0}}
  end

  @impl true
  def handle_cast({:route, %{domain: domain} = event}, state) do
    route_to_handler(domain, event)
    {:noreply, %{state | routed: state.routed + 1}}
  end

  defp route_to_handler(domain, event) do
    prefix = domain |> String.split("/") |> List.first()

    case prefix do
      "runtime" -> TelemetryGateway.Handler.RuntimeHandler.handle(event)
      "scientific" -> TelemetryGateway.Handler.ScienceHandler.handle(event)
      "engineering" -> TelemetryGateway.Handler.EngineeringHandler.handle(event)
      "knowledge" -> TelemetryGateway.Handler.KnowledgeHandler.handle(event)
      "governance" -> TelemetryGateway.Handler.GovernanceHandler.handle(event)
      "planetary" -> TelemetryGateway.Handler.PlanetaryHandler.handle(event)
      "certification" -> TelemetryGateway.Handler.CertificationHandler.handle(event)
      "evolution" -> TelemetryGateway.Handler.EvolutionHandler.handle(event)
      _ -> :ok
    end
  end
end
