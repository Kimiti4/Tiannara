defmodule Tiannara.Evolution.Metrics do
  @moduledoc """
  The four-dimensional measurement model for an evolutionary cycle.

  Constitutional basis: Success Metrics, Evolution Framework, "Measure success
  using meaningful outcomes rather than superficial metrics."
  """

  defstruct capability: %{},
            epistemic: %{},
            architectural: %{},
            constitutional: %{}

  @type t :: %__MODULE__{}
end