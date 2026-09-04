defmodule Tiannara.Executive.BootManager.ServiceLifecycle do
  @valid_states [:pending, :starting, :healthy, :degraded, :recovering, :failed, :stopped]

  defstruct state: :pending, supervisor_status: :unknown, health_status: :unknown, last_transition: nil, metadata: %{}

  def transition(%__MODULE__{state: current} = fsm, new_state, metadata \\ %{}) when new_state in @valid_states do
    if valid_transition?(current, new_state) do
      %__MODULE__{fsm | state: new_state, last_transition: DateTime.utc_now(), metadata: Map.merge(fsm.metadata, metadata)}
    else
      require Logger; Logger.error("[Lifecycle] Invalid transition: #{current} -> #{new_state}"); fsm
    end
  end

  defp valid_transition?(:pending, :starting), do: true
  defp valid_transition?(:starting, s) when s in [:healthy, :degraded, :failed], do: true
  defp valid_transition?(:healthy, s) when s in [:degraded, :recovering, :stopped], do: true
  defp valid_transition?(:degraded, s) when s in [:healthy, :recovering, :failed, :stopped], do: true
  defp valid_transition?(:recovering, s) when s in [:healthy, :degraded, :failed, :stopped], do: true
  defp valid_transition?(:failed, :recovering), do: true
  defp valid_transition?(_, _), do: false

  def reconcile(fsm, supervisor_status, health_status) do
    fsm = %{fsm | supervisor_status: supervisor_status, health_status: health_status}
    cond do
      supervisor_status == :running and health_status == :healthy -> transition(fsm, :healthy)
      supervisor_status == :running and health_status == :degraded -> transition(fsm, :degraded)
      supervisor_status == :stopped -> transition(fsm, :stopped)
      true -> fsm
    end
  end
end
