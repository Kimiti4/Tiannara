defmodule Tiannara.Logic.Contradiction do
  @moduledoc """
  Canonical contradiction-detection kernel (MC-002 L4).

  Exposes the two structural primitives every correct contradiction flow in
  the system reduces to:

    - `detect/2` — a symmetric verdict over a pair of claims;
    - `from_refutations/1` — lifts evidence-link refutations that survive
      `detect/2` into a shared contradiction structure.

  Logic sits ABOVE Math in the stack (archaeology §4): claims may carry
  `:confidence` scores computed by the Math/Probability layer, but the kernel
  itself never computes confidence — it reasons over `subject`, `value` and
  `timestamp` structure only. Faithfulness over apparent capability.

  Constitutional basis: Scientific Method, "Evidence Before Confidence".
  """

  @type claim :: %{
          required(:subject) => term(),
          required(:value) => term(),
          optional(:timestamp) => term(),
          optional(:confidence) => float()
        }

  @type verdict :: :contradiction | :consistent | :unknown

  @doc """
  Structural verdict for a pair of claims.

  - `:contradiction` — same subject, differing values;
  - `:consistent` — same subject, same value;
  - `:unknown` — subjects differ, a subject/value is missing, or the claims
    are not structurally comparable. `:unknown` is never coerced into either
    positive verdict; an unavailable epistemic determination must not be
    interpreted as successful validation.
  """
  @spec detect(claim :: term(), claim :: term()) :: verdict()
  def detect(%{subject: sa, value: va}, %{subject: sb, value: vb})
      when not is_nil(sa) and not is_nil(sb) and not is_nil(va) and not is_nil(vb) do
    cond do
      sa != sb -> :unknown
      va == vb -> :consistent
      true -> :contradiction
    end
  end

  def detect(_a, _b), do: :unknown

  @doc """
  Lift a list of refutation links into confirmed contradictions.

  Each refutation is a `%{claim_a: _, claim_b: _}` map or a `{claim_a, claim_b}`
  tuple (optionally nested in an `:payload` key). Only links whose pairwise
  `detect/2` verdict is `:contradiction` are retained; everything else is
  dropped so an unsettled link is never promoted to a confirmed contradiction.

  Returns a list of maps shaped as
  `%{type: :direct_contradiction, subject: _, claim_a: _, claim_b: _}`.
  """
  @spec from_refutations([term()]) :: [map()]
  def from_refutations(refutations) when is_list(refutations) do
    refutations
    |> Enum.map(&normalize_refutation/1)
    |> Enum.flat_map(fn
      {:ok, claim_a, claim_b} ->
        case detect(claim_a, claim_b) do
          :contradiction ->
            [
              %{
                type: :direct_contradiction,
                subject: subject_of(claim_a, claim_b),
                claim_a: claim_a,
                claim_b: claim_b
              }
            ]

          _ ->
            []
        end

      :unverifiable ->
        []
    end)
  end

  defp normalize_refutation(%{claim_a: claim_a, claim_b: claim_b}),
    do: {:ok, claim_a, claim_b}

  defp normalize_refutation({claim_a, claim_b}) when is_map(claim_a) and is_map(claim_b),
    do: {:ok, claim_a, claim_b}

  defp normalize_refutation({claim_a, claim_b}) when is_map(claim_a) or is_map(claim_b),
    do: {:ok, claim_a, claim_b}

  defp normalize_refutation(_), do: :unverifiable

  defp subject_of(%{subject: s}, _b) when not is_nil(s), do: s
  defp subject_of(_a, %{subject: s}) when not is_nil(s), do: s
  defp subject_of(_a, _b), do: nil
end