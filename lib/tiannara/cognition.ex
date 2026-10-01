defmodule Tiannara.Cognition do
  @moduledoc "Reasoning, planning and world-model APIs for the Core."

  defstruct []

  @doc "Planning requires an actual planning backend; never fabricate a plan."
  def plan(_state, _goal), do: {:error, :planning_backend_unavailable}
end
