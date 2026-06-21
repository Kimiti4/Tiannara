defmodule Tiannara.Cognition do
  @moduledoc "Reasoning, planning and world-model APIs for the Core."

  defstruct []

  @doc "Placeholder planning API — returns an example tuple."
  def plan(_state, _goal), do: {:ok, :no_plan_available}
end
