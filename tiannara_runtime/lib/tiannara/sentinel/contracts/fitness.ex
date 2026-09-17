defmodule Tiannara.Sentinel.Contracts.Fitness do
  @moduledoc """
  Canonical contract for evaluating the constitutional integrity of an outcome.
  """
  @enforce_keys [:stability, :novelty, :constraint_compliance, :entropy_regulation, :total]

  defstruct [
    :stability,
    :novelty,
    :constraint_compliance,
    :entropy_regulation,
    :total
  ]
end
