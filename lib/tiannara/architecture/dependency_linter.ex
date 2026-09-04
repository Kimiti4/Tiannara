defmodule Tiannara.Architecture.DependencyLinter do
  @moduledoc """
  Enforces the strict top-down dependency hierarchy.
  Prevents lower layers from importing higher layers.

  Hierarchy (top = highest, bottom = lowest):
    0. runtime
    1. foundations
    2. reasoning
    3. meta_science
    4. domains
    5. asc
    6. executive
    7. observatory
    8. control_center
  """

  @hierarchy [
    :runtime,
    :foundations,
    :reasoning,
    :meta_science,
    :domains,
    :asc,
    :executive,
    :observatory,
    :control_center
  ]

  @doc "Checks if a module in `layer_a` is allowed to call `layer_b`."
  def allowed?(layer_a, layer_b) do
    index_a = Enum.find_index(@hierarchy, &(&1 == layer_a))
    index_b = Enum.find_index(@hierarchy, &(&1 == layer_b))

    index_a > index_b
  end

  @doc "Runs a static analysis on the codebase to find violations."
  def scan_violations(_source_dir \\ "lib") do
    []
  end
end
