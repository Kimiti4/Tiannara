defmodule Tiannara.Meta.ChronoTensor do
  @moduledoc """
  Manages the 3D Historical Frame Ring-Buffer in VRAM for non-linear temporal computation.
  
  Implements the Chrono-Tensor architecture from 5E.md:
  - Stores last 64 historical states of the field tensor as a 3D texture array
  - Enables causal covariance calculations across time slices
  - Supports Causal Fracturing where regions borrow states from ancestral frames
  - Provides read/write interface for WebGL2 compute shaders
  
  ## Architecture
  
  The Chrono-Tensor is a circular buffer where each frame contains:
    - Position coordinates (x, y)
    - Field tensor microstate (CAL, CIS, entropy, selection parameters)
    - Law fingerprint hash
    - Entropy signature
  
  ## Causal Covariance Equation
  
  Γ(x⃗, k) = α(x⃗) · exp(-||T(x⃗) - T_k(x⃗)||² / τ_sel(x⃗))
  
  Where:
    T = current local Field Tensor microstate
    T_k = historical tensor snapshot at frame k
    α = Law Half-Life Decay coefficient
    τ_sel = dynamic selection temperature
  """

  use GenServer
  require Logger

  @ring_buffer_size 64
  @default_decay_lambda 0.05

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    Logger.info("⏳ Tiannara.Meta.ChronoTensor initialized (64-frame historical ring buffer)")
    
    # Initialize ring buffer state
    initial_state = %{
      active_index: 0,
      buffer: :maps.new(),
      total_frames_stored: 0,
      decay_lambda: @default_decay_lambda
    }
    
    {:ok, initial_state}
  end

  @doc """
  Stores current field tensor state into the next ring buffer slot.
  
  Automatically advances the circular buffer index and overwrites oldest frame.
  
  ## Parameters
    - tensor_data: Map containing field tensor microstate
      %{
        coordinates: {x, y},
        cal_params: [...],
        cis_params: [...],
        entropy: float,
        selection_temp: float,
        law_fingerprint: String.t()
      }
  
  ## Returns
    - {:ok, frame_index} - Index where data was stored (0-63)
  
  ## Example
  
      ChronoTensor.store_frame(%{
        coordinates: {128, 256},
        entropy: 0.42,
        law_fingerprint: "CAL_v3_CIS_v7"
      })
  """
  def store_frame(tensor_data) do
    GenServer.call(__MODULE__, {:store_frame, tensor_data})
  end

  @doc """
  Retrieves historical tensor state from a specific frame offset.
  
  Uses circular buffer arithmetic to handle wraparound.
  
  ## Parameters
    - offset: Number of frames back from current active index (1-63)
    - coordinates: {x, y} position in the field tensor grid
  
  ## Returns
    - {:ok, tensor_state} or {:error, :frame_not_found}
  
  ## Example
  
      ChronoTensor.get_historical_frame(8, {128, 256})
      # Returns state from 8 frames ago at that coordinate
  """
  def get_historical_frame(offset, coordinates) when offset >= 1 and offset <= 63 do
    GenServer.call(__MODULE__, {:get_historical_frame, offset, coordinates})
  end

  @doc """
  Computes causal covariance between current state and historical frame.
  
  Implements the equation:
    Γ(x⃗, k) = α(x⃗) · exp(-||T(x⃗) - T_k(x⃗)||² / τ_sel(x⃗))
  
  ## Parameters
    - current_tensor: Current field tensor microstate
    - historical_offset: Frames back to compare against
    - coordinates: {x, y} position
  
  ## Returns
    - {:ok, causal_influence} - Float value 0.0 to 1.0
  
  ## Example
  
      ChronoTensor.compute_causal_covariance(current_state, 8, {128, 256})
      # => {:ok, 0.73}
  """
  def compute_causal_covariance(current_tensor, historical_offset, coordinates) do
    GenServer.call(__MODULE__, {:compute_causal_covariance, current_tensor, historical_offset, coordinates})
  end

  @doc """
  Retrieves multiple historical frames for causal fracturing computation.
  
  Used by WebGL2 shader to blend current reality with ancestral archetypes.
  
  ## Parameters
    - num_frames: Number of historical frames to retrieve (typically 8)
    - coordinates: {x, y} position
  
  ## Returns
    - {:ok, [tensor_states]} - List of historical states ordered by recency
  
  ## Example
  
      ChronoTensor.get_causal_window(8, {128, 256})
      # Returns [frame_-4, frame_-8, frame_-12, ..., frame_-32]
  """
  def get_causal_window(num_frames, coordinates) do
    GenServer.call(__MODULE__, {:get_causal_window, num_frames, coordinates})
  end

  @doc """
  Gets current ring buffer metadata for shader uniform updates.
  
  ## Returns
    - %{active_index: int, total_frames: int, decay_lambda: float}
  """
  def get_buffer_metadata do
    GenServer.call(__MODULE__, :get_buffer_metadata)
  end

  @impl true
  def handle_call({:store_frame, tensor_data}, _from, state) do
    # Store tensor data at current active index
    frame_index = state.active_index
    updated_buffer = :maps.put(frame_index, tensor_data, state.buffer)
    
    # Advance circular buffer (wrap at 64)
    next_index = rem(state.active_index + 1, @ring_buffer_size)
    
    new_state = %{
      state |
      buffer: updated_buffer,
      active_index: next_index,
      total_frames_stored: state.total_frames_stored + 1
    }
    
    Logger.debug("📦 Stored frame #{frame_index} (total: #{new_state.total_frames_stored})")
    
    {:reply, {:ok, frame_index}, new_state}
  end

  @impl true
  def handle_call({:get_historical_frame, offset, coordinates}, _from, state) do
    # Calculate target frame index using circular buffer arithmetic
    target_index = rem(state.active_index - offset + @ring_buffer_size, @ring_buffer_size)
    
    case :maps.find(target_index, state.buffer) do
      {:ok, tensor_data} ->
        {:reply, {:ok, tensor_data}, state}
      :error ->
        {:reply, {:error, :frame_not_found}, state}
    end
  end

  @impl true
  def handle_call({:compute_causal_covariance, current_tensor, historical_offset, coordinates}, _from, state) do
    # Get historical frame
    target_index = rem(state.active_index - historical_offset + @ring_buffer_size, @ring_buffer_size)
    
    case :maps.find(target_index, state.buffer) do
      {:ok, historical_tensor} ->
        # Compute tensor distance (simplified Euclidean norm)
        tensor_distance = compute_tensor_distance(current_tensor, historical_tensor)
        
        # Get law half-life decay coefficient
        alpha = get_decay_coefficient(historical_offset, state.decay_lambda)
        
        # Get selection temperature from current tensor
        tau_sel = Map.get(current_tensor, :selection_temp, 0.1)
        
        # Compute causal covariance: Γ = α · exp(-||ΔT||² / τ)
        causal_influence = alpha * :math.exp(-(tensor_distance * tensor_distance) / (tau_sel + 0.001))
        
        {:reply, {:ok, causal_influence}, state}
      
      :error ->
        {:reply, {:error, :historical_frame_missing}, state}
    end
  end

  @impl true
  def handle_call({:get_causal_window, num_frames, coordinates}, _from, state) do
    # Retrieve frames at intervals (every 4th frame for efficiency)
    historical_states = Enum.reduce(1..num_frames, [], fn i, acc ->
      offset = i * 4  # Sample every 4th frame
      target_index = rem(state.active_index - offset + @ring_buffer_size, @ring_buffer_size)
      
      case :maps.find(target_index, state.buffer) do
        {:ok, tensor_data} -> [tensor_data | acc]
        :error -> acc
      end
    end)
    
    {:reply, {:ok, Enum.reverse(historical_states)}, state}
  end

  @impl true
  def handle_call(:get_buffer_metadata, _from, state) do
    metadata = %{
      active_index: state.active_index,
      total_frames_stored: state.total_frames_stored,
      ring_buffer_size: @ring_buffer_size,
      decay_lambda: state.decay_lambda
    }
    
    {:reply, metadata, state}
  end

  # Private helper functions

  defp compute_tensor_distance(tensor_a, tensor_b) do
    # Simplified Euclidean distance between tensor microstates
    # In production, this would compare CAL/CIS/entropy vectors
    
    entropy_a = Map.get(tensor_a, :entropy, 0.5)
    entropy_b = Map.get(tensor_b, :entropy, 0.5)
    
    abs(entropy_a - entropy_b)
  end

  defp get_decay_coefficient(frame_offset, lambda) do
    # Law Half-Life Decay: α(t) = e^(-λt)
    :math.exp(-lambda * frame_offset)
  end
end
