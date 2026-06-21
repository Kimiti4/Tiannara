defmodule Tiannara.Identity do
  @moduledoc "Identity field and self-model for Tiannara Core."

  defstruct [:id, :self_model, :goals, :values, :preferences]

  @doc "Create a new identity struct."
  def new(id, attrs \\ %{}) do
    %__MODULE__{
      id: id,
      self_model: Map.get(attrs, :self_model, %{}),
      goals: Map.get(attrs, :goals, []),
      values: Map.get(attrs, :values, %{}),
      preferences: Map.get(attrs, :preferences, %{})
    }
  end
end
