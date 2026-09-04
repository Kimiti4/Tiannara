defmodule Tiannara.Omega.ExperimentSpec do
  @moduledoc """
  A concrete, falsifiable experiment specification produced by the
  ExperimentGenerator. Consumed by the PatchGenerator.
  """

  @enforce_keys [:id, :proposal_id, :hypothesis_id]
  defstruct [
    :id,
    :proposal_id,
    :hypothesis_id,
    :statement,
    :prediction,
    :falsifier,
    :method,
    :success_criteria,
    :lineage
  ]

  @type t :: %__MODULE__{}
end