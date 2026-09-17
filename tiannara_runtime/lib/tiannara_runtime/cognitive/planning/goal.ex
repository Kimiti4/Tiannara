defmodule TiannaraRuntime.Cognitive.Planning.Goal do
  @moduledoc "Phase 18.5 — Planning goal struct"

  defstruct [:id, :description, :parent_goal, :sub_goals, :status]

  def new(fields) do
    id = generate_id(fields)
    struct = %__MODULE__{
      id: id,
      description: fields.description,
      parent_goal: fields.parent_goal,
      sub_goals: fields.sub_goals || [],
      status: fields.status || :active
    }
    {:ok, struct}
  end

  defp generate_id(fields) do
    base = "#{fields.description}_#{:erlang.unique_integer([:positive])}"
    hash = :crypto.hash(:sha256, base) |> Base.encode16(case: :lower) |> String.slice(0, 16)
    "pg_#{hash}"
  end
end
