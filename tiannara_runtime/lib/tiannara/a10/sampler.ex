defmodule Tiannara.A10.Sampler do
  @moduledoc """
  Multi-scale extractor from EventAggregator.
  Compresses trajectory samples into a D(t) vector and sends to DriftTensor.
  """
  use GenServer

  def start_link(_) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def init(_) do
    # Sample every 100ms in simulation time
    :timer.send_interval(100, :sample)
    {:ok, %{}}
  end

  def handle_info(:sample, state) do
    events = Tiannara.Telemetry.EventAggregator.get_events()
    
    # Calculate simple D(t) = [d_s, d_t, d_e, d_o, d_c]
    # In a real system, these would be precise numerical mappings
    # Here we approximate from event counts in the recent history
    recent = Enum.take(events, 50)
    
    d_s = Enum.count(recent, &(&1.name == :mutation_proposed)) * 0.1
    d_t = Enum.count(recent, &(&1.name == :pressure_update)) * 0.1
    d_e = Enum.count(recent, &(&1.name == :entropy_spike)) * 0.5
    d_o = Enum.count(recent, &(&1.name == :observer_free_invalid)) * 0.8
    d_c = Enum.count(recent, &(&1.name == :execute_regulation)) * 0.2

    d_vector = [d_s, d_t, d_e, d_o, d_c]
    
    GenServer.cast(Tiannara.A10.DriftTensor, {:record_sample, d_vector})
    
    {:noreply, state}
  end
end
