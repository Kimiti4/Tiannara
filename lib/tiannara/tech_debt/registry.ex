defmodule Tiannara.TechDebt.Registry do
  @moduledoc """
  Tracks tech-debt items, prioritizes them by severity, and records resolution.
  Constitutional basis: Continuous Self-Evaluation, Observability, "Maintain
  audit trails."
  """

  alias Tiannara.TechDebt.Item

  defstruct items: []

  def new, do: %__MODULE__{}

  def add(%__MODULE__{} = registry, %Item{} = item),
    do: %{registry | items: registry.items ++ [item]}

  def add_all(%__MODULE__{} = registry, items) when is_list(items),
    do: %{registry | items: registry.items ++ items}

  def open_items(%__MODULE__{items: items}),
    do: Enum.filter(items, &(&1.status == :open))

  def resolve(%__MODULE__{} = registry, id, note \\ nil) do
    items =
      Enum.map(registry.items, fn
        %Item{id: ^id} = item -> %{item | status: :resolved, notes: item.notes ++ List.wrap(note)}
        item -> item
      end)

    %{registry | items: items}
  end

  def prioritize(%__MODULE__{items: items}) do
    Enum.sort_by(items, &(-Item.severity_rank(&1.severity)))
  end
end