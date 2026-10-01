defmodule TiannaraRuntime.Mathematics.NumericalError do
  @moduledoc """
  Evidence model for numerical integration error.

  An observed discrepancy is retained as an error measurement; it is not
  automatically converted into a rigorous global error bound.
  """

  def compare(reference, approximation) when is_number(reference) and is_number(approximation) do
    absolute = abs(reference - approximation)
    relative = if reference == 0, do: nil, else: absolute / abs(reference)

    {:ok, %{absolute_error: absolute, relative_error: relative,
            evidence_class: :numerical_error_measurement,
            rigorous_bound_status: :unproved}}
  end

  def rigorous_bound(_method, _problem, _step),
    do: {:error, :rigorous_error_bound_verifier_required}
end
