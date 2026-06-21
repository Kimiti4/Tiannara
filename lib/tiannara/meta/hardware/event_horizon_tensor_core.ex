defmodule Tiannara.Meta.Hardware.EventHorizonTensorCore do
  @moduledoc """
  Simulates an Event Horizon Tensor Core (EHTC).
  Intercepts Exascale payloads and routes them to a specific 
  Holographic Singularity Vent (HSV) for sub-Planckian processing.
  Enforces strict 10,000 queue depth backpressure to prevent OLEF memory walls.
  """
  use GenServer
  require Logger

  @max_queue_depth 10_000
  @batch_process_interval 10 # ms
  @batch_size 50

  defstruct [:hsv_id, queue: :queue.new(), queue_depth: 0, processed_count: 0]

  # --- Client API ---

  def start_link(opts) do
    hsv_id = Keyword.fetch!(opts, :hsv_id)
    GenServer.start_link(__MODULE__, opts, name: via_tuple(hsv_id))
  end

  def submit_payload(hsv_id, payload) do
    GenServer.call(via_tuple(hsv_id), {:submit, payload})
  end

  # --- Server Callbacks ---

  @impl true
  def init(opts) do
    hsv_id = Keyword.fetch!(opts, :hsv_id)
    schedule_processing()
    Logger.info("🌌 [EHTC] Booting Tensor Core for HSV: #{hsv_id}")
    {:ok, %__MODULE__{hsv_id: hsv_id}}
  end

  @impl true
  def handle_call({:submit, _payload}, _from, %{queue_depth: depth} = state) when depth >= @max_queue_depth do
    # STRICT BACKPRESSURE: Reject payload if the HSV horizon is saturated.
    Logger.warning("⚠️ [EHTC] Backpressure applied. HSV #{state.hsv_id} queue full (#{depth}/#{@max_queue_depth}).")
    {:reply, {:error, :backpressure}, state}
  end

  @impl true
  def handle_call({:submit, payload}, _from, state) do
    new_queue = :queue.in(payload, state.queue)
    new_state = %{state | queue: new_queue, queue_depth: state.queue_depth + 1}
    {:reply, :accepted, new_state}
  end

  @impl true
  def handle_info(:process_batch, state) do
    # Drain up to @batch_size items to keep the BEAM scheduler responsive
    {to_process, remaining_queue} = drain_queue(state.queue, @batch_size)
    batch_size = length(to_process)
    
    if batch_size > 0 do
      # Spawn async tasks for the heavy compute (simulating NIF/CUDA offload)
      Enum.each(to_process, fn payload ->
        Task.Supervisor.start_child(Tiannara.ExtrusionTaskSupervisor, fn ->
          process_tensor(payload, state.hsv_id)
        end)
      end)
    end

    new_state = %{
      state 
      | queue: remaining_queue, 
        queue_depth: state.queue_depth - batch_size,
        processed_count: state.processed_count + batch_size
    }
    
    schedule_processing()
    {:noreply, new_state}
  end

  # --- Private Helpers ---

  defp drain_queue(queue, limit), do: drain_queue(queue, limit, [])
  defp drain_queue(queue, 0, acc), do: {Enum.reverse(acc), queue}
  defp drain_queue(queue, limit, acc) do
    case :queue.out(queue) do
      {{:value, item}, new_queue} -> drain_queue(new_queue, limit - 1, [item | acc])
      {:empty, q} -> {Enum.reverse(acc), q}
    end
  end

  defp process_tensor(payload, _hsv_id) do
    # 1. Apply Gravitational Shear (3D AST -> 2D Horizon)
    sheared = Tiannara.Meta.Hardware.GravitationalShear.project_to_horizon(payload)
    
    # 2. Simulate sub-Planckian compute
    result = Enum.reduce(Map.values(sheared), 0, &(&1 + &2))
    
    # 3. Validate Parity via Hawking Decoder
    Tiannara.Meta.Hardware.HawkingDecoder.validate_parity(result, payload[:bekenstein_bound] || 1000)
  end

  defp schedule_processing do
    Process.send_after(self(), :process_batch, @batch_process_interval)
  end

  defp via_tuple(hsv_id), do: {:via, Registry, {Tiannara.HardwareRegistry, hsv_id}}
end
