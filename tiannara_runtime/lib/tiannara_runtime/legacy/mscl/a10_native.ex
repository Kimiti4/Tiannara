defmodule TiannaraRuntime.Legacy.Tiannara.MSCL.A10Native do
  @moduledoc """
  Computes the Lyapunov snapshot directly from the Zero-Copy ETS Pointer Registry.
  """
  
  alias Tiannara.Native.A10
  alias TiannaraRuntime.SharedMemory

  @doc """
  Computes the Lyapunov function snapshot V(x) from shared memory.
  """
  def compute_snapshot(gain_matrix) do
    with {:ok, ref} <- SharedMemory.get_state_ref() do
      A10.lyapunov_shared(ref, gain_matrix)
    end
  end

  @doc """
  Computes the A10 drift tensor directly from shared memory.
  """
  def process_drift(window_size \\ 5) do
    with {:ok, ref} <- SharedMemory.get_state_ref() do
      A10.compute_drift_shared(ref, window_size)
    end
  end
end
