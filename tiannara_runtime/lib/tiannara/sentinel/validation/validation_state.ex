defmodule Tiannara.Sentinel.Validation.ValidationState do
  @moduledoc """
  Holds the state of the Phase D.0 certification run so the dashboard can query it.
  """
  use Agent

  def start_link(_) do
    Agent.start_link(fn -> nil end, name: __MODULE__)
  end

  def get_report do
    Agent.get(__MODULE__, & &1)
  end

  def set_report(report) do
    Agent.update(__MODULE__, fn _ -> report end)
  end
end
