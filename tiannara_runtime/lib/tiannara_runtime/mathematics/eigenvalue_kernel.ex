defmodule TiannaraRuntime.Mathematics.EigenvalueKernel do
  @moduledoc """
  Exact small-matrix spectral substrate.

  Supported matrices are deliberately limited to avoid pretending that a
  general eigenvalue solver exists. Results are mathematical objects and do
  not by themselves certify physical stability.
  """

  def analyze([[a, b], [c, d]]) when is_number(a) and is_number(b) and is_number(c) and is_number(d) do
    trace = a + d
    determinant = a * d - b * c
    discriminant = trace * trace - 4 * determinant

    {:ok, %{
      dimension: 2,
      trace: trace,
      determinant: determinant,
      characteristic_polynomial: {:quadratic, trace, determinant},
      discriminant: discriminant,
      eigenvalue_status: if(discriminant >= 0, do: :real_or_repeated, else: :complex_pair),
      evidence_class: :exact_symbolic_numeric,
      reality_status: :mathematical_only
    }}
  end

  def analyze(_), do: {:error, :unsupported_matrix}
end
