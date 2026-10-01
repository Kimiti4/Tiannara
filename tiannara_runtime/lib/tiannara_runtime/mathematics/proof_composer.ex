defmodule TiannaraRuntime.Mathematics.ProofComposer do
  @moduledoc """
  Composes independently established proof fragments into an auditable proof
  artifact. Composition itself cannot manufacture missing proof evidence.
  """

  def compose(fragments) when is_list(fragments) do
    if fragments != [] and Enum.all?(fragments, &valid_fragment?/1) do
      {:ok, %{status: :composed, fragments: fragments, certification_eligible: false}}
    else
      {:error, :unproved_fragment_present}
    end
  end

  defp valid_fragment?(%{status: :proved, evidence: evidence}) when is_map(evidence), do: true
  defp valid_fragment?(_), do: false
end
