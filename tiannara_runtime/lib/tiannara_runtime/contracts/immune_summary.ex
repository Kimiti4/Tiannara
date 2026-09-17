defmodule TiannaraRuntime.Contracts.ImmuneSummary do
  @moduledoc """
  Aggregated upward-only summary from constraint layer to meta-governance.
  """

  @enforce_keys [:stability_index, :collapse_probability, :oscillation_score]
  defstruct [:stability_index, :collapse_probability, :oscillation_score]

  @type t :: %__MODULE__{
          stability_index: float(),
          collapse_probability: float(),
          oscillation_score: float()
        }
end
