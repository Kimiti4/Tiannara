defmodule Tiannara.UCC.NATSConsumer do
  @moduledoc """
  Subscribes to the NATS streams emitted by the Python physics engine.
  Routes the JSON genomes into the Registries.
  """
  use GenServer

  alias Tiannara.UCC.{InstitutionGenome, ConstitutionGenome, MacroStateRegistry, ConstitutionAttractorRegistry}

  # This is a stub for the actual NATS client callback (e.g. using Gnat)
  def start_link(_) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  @impl true
  def init(state) do
    # In a real implementation:
    # Gnat.sub(:gnat_connection, self(), "ucc.institution.genome")
    # Gnat.sub(:gnat_connection, self(), "ucc.constitution.genome")
    {:ok, state}
  end

  @impl true
  def handle_info({:msg, %{topic: "ucc.institution.genome", body: body}}, state) do
    case Jason.decode(body, keys: :atoms) do
      {:ok, data} ->
        genome = struct(InstitutionGenome, data)
        MacroStateRegistry.register_institution(genome.id, genome)
      _ -> :error
    end
    {:noreply, state}
  end

  @impl true
  def handle_info({:msg, %{topic: "ucc.constitution.genome", body: body}}, state) do
    case Jason.decode(body, keys: :atoms) do
      {:ok, data} ->
        genome = struct(ConstitutionGenome, data)
        # We assume the Python side might also push the fitness metrics (fri, trh, ee) in the payload wrapper
        # For now we register with default fitness, or parse them if provided.
        ConstitutionAttractorRegistry.register_attractor(genome.id, genome, 0.0, 0, 0.0)
      _ -> :error
    end
    {:noreply, state}
  end
end
