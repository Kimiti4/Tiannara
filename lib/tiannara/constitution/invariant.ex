defmodule Tiannara.Constitution.Invariant do
  @moduledoc """
  A single constitutional invariant as an executable probe.

  The probe re-verifies a "must never" guarantee against the live enforcement
  mechanism, returning `:ok` if the guarantee holds or `{:error, reason}` if it
  is violated. This makes the constitution continuously testable rather than
  merely documented.

  Constitutional basis: "Capability must never outpace verification",
  "No feature is complete until it is validated", "Evidence Before Confidence."
  """

  @type probe :: (-> :ok | {:error, term()})

  @enforce_keys [:id, :description, :category, :probe]
  defstruct [:id, :description, :category, :probe]

  def new(id, description, category, probe) when is_function(probe, 0) do
    %__MODULE__{id: id, description: description, category: category, probe: probe}
  end
end