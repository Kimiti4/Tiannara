defmodule Tiannara.Memory.Ladder do
  @moduledoc """
  The memory-promotion ladder:

      data → information → knowledge → pattern → model → principle →
      generalized_understanding → engineering_insight → scientific_discovery

  Memory exists to improve reasoning, not merely store information. Promotion
  between rungs is EVIDENCE-GATED: a rung cannot be claimed without the
  evidence it requires ("Evidence Before Confidence").
  """

  @rungs [
    :data,
    :information,
    :knowledge,
    :pattern,
    :model,
    :principle,
    :generalized_understanding,
    :engineering_insight,
    :scientific_discovery
  ]

  @requirements %{
    data: [],
    information: [:source, :context],
    knowledge: [:corroboration],
    pattern: [:recurrence],
    model: [:mechanism],
    principle: [:generalization, :validation],
    generalized_understanding: [:integration],
    engineering_insight: [:application],
    scientific_discovery: [:novelty, :independent_confirmation]
  }

  def rungs, do: @rungs

  def rank(rung), do: Enum.find_index(@rungs, &(&1 == rung))

  def above?(a, b), do: rank(a) > rank(b)

  def requirements(rung), do: Map.get(@requirements, rung, [])

  @doc "Ascending rungs strictly above `from` up to and including `to`."
  def path(from, to) do
    fi = rank(from)
    ti = rank(to)
    if ti <= fi, do: [], else: Enum.slice(@rungs, (fi + 1)..ti)
  end

  @doc "Returns :ok or {:missing, keys} for the rung's evidence requirements."
  def satisfied?(rung, evidence) when is_map(evidence) do
    missing =
      requirements(rung)
      |> Enum.reject(fn key -> present?(Map.get(evidence, key)) end)

    if missing == [], do: :ok, else: {:missing, missing}
  end

  defp present?(nil), do: false
  defp present?([]), do: false
  defp present?(_), do: true
end
