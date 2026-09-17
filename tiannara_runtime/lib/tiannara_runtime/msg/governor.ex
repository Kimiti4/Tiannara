defmodule TiannaraRuntime.MSG.Governor do
  @moduledoc """
  Meta-Stability Governor (MSG) Core.

  Tracks active stabilizer interventions (intensity and frequency), and computes
  the stabilization pressure $M$:
  $$M = \\frac{\\sum |I_i|}{A_{adaptive} + \\epsilon}$$

  If M exceeds 0.85, the system is flagged as overregulated (stagnant),
  allowing the runtime to throttle aggressive correction loops and preserve
  adaptive freedom.
  """

  use GenServer
  require Logger

  @overregulation_threshold 0.85
  @adaptive_window_ms 5000
  @epsilon 0.001

  # ==================== Public API ====================

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc """
  Propose an intervention from a stabilizer. Returns :ok or :throttled based on pressure M.
  """
  def propose_intervention(stabilizer, intensity) when is_atom(stabilizer) and is_number(intensity) do
    GenServer.call(__MODULE__, {:propose, stabilizer, intensity})
  end

  @doc """
  Get the current stabilization pressure M.
  """
  def get_pressure do
    GenServer.call(__MODULE__, :get_pressure)
  end

  @doc """
  Check if the system is currently overregulated.
  """
  def overregulated? do
    GenServer.call(__MODULE__, :overregulated?)
  end

  # ==================== GenServer Callbacks ====================

  @impl true
  def init(_opts) do
    Logger.info("🛡️ [MSG Governor] Initialized")
    {:ok, initial_state()}
  end

  @impl true
  def handle_call({:propose, stabilizer, intensity}, _from, state) do
    now = System.system_time(:millisecond)

    # 1. Prune historical interventions outside the window
    recent_interventions = prune_expired(state.interventions, now)

    # 2. Record new intervention
    new_interventions = [{stabilizer, intensity, now} | recent_interventions]

    # 3. Compute M
    total_intensity = Enum.sum(Enum.map(new_interventions, fn {_, i, _} -> i end))

    # Adaptive activity is derived from unique stabilizers operating in this window
    unique_count = new_interventions |> Enum.map(fn {s, _, _} -> s end) |> Enum.uniq() |> length()
    adaptive_activity = max(unique_count * 0.5, 0.1)

    m = total_intensity / (adaptive_activity + @epsilon)

    # 4. Check if we should throttle
    {decision, next_state} =
      if m > @overregulation_threshold do
        Logger.warning("⚠️ [MSG] Overregulation detected: M = #{Float.round(m, 4)} (limit: #{@overregulation_threshold}). Throttling #{stabilizer}!")
        {:throttled, %{state | interventions: recent_interventions, pressure: m}}
      else
        {:ok, %{state | interventions: new_interventions, pressure: m}}
      end

    {:reply, decision, next_state}
  end

  @impl true
  def handle_call(:get_pressure, _from, state) do
    {:reply, state.pressure, state}
  end

  @impl true
  def handle_call(:overregulated?, _from, state) do
    {:reply, state.pressure > @overregulation_threshold, state}
  end

  @impl true
  def handle_call(:reset, _from, _state) do
    {:reply, :ok, initial_state()}
  end

  @impl true
  def handle_cast(:reset, _state) do
    {:noreply, initial_state()}
  end

  # ==================== Helper Functions ====================

  defp initial_state do
    %{
      interventions: [],
      pressure: 0.0
    }
  end

  defp prune_expired(interventions, now) do
    cutoff = now - @adaptive_window_ms
    Enum.filter(interventions, fn {_, _, ts} -> ts > cutoff end)
  end
end
