defmodule Tiannara.Omega.HumanDelivery.ExplanationTest do
  use ExUnit.Case
  alias Tiannara.Omega.HumanDelivery.Explanation

  test "builds and renders explanation" do
    package = %{
      explanation_id: :expl_123,
      detected: "system overload",
      investigated: "memory usage",
      hypotheses: ["memory leak", "concurrent load"],
      selected_experiment: %{id: :exp_memleak},
      generated_candidate: %{id: :cand_456},
      sandbox_result: %{status: :pass},
      certification_confidence: 0.93,
      uncertainty: %{source: "incomplete data"},
      evidence: ["log: high memory", "trace: GC pressure"],
      lineage: [:decision_abc, :analysis_xyz]
    }

    explanation = Explanation.build(package)
    narrative = Explanation.render_narrative(explanation)

    assert String.contains?(narrative, "system overload")
    assert String.contains?(narrative, "hypotheses")
    assert String.contains?(narrative, "memory leak")
    assert String.contains?(narrative, "concurrent load")
    assert String.contains?(narrative, "exp_memleak")
    assert String.contains?(narrative, "cand_456")
    assert String.contains?(narrative, "passed sandbox")
    assert String.contains?(narrative, "Certification confidence is 0.93")
    assert String.contains?(narrative, "Uncertainty")
    assert String.contains?(narrative, "Lineage trace")
    assert String.contains?(narrative, "deployment requires human authorization")
  end
end
defmodule Tiannara.Omega.HumanDelivery.Explanation do
  @moduledoc """
  A structured, transparent explanation that Tiannara delivers to a human.

  This is the narrative contract made into data: every explanation states what
  was detected, investigated, hypothesized, experimented on, generated,
  validated, and certified — together with confidence AND uncertainty. It
  always ends by declaring that deployment requires human authorization.

  Constitutional basis: augmentation clause (final constitutional clause),
  Explainability, "Uncertainty should never be hidden", "Evidence Before
  Confidence."
  """

  @enforce_keys [:explanation_id, :detected]
  defstruct [
    :explanation_id,
    :detected,
    :investigated,
    :hypotheses,
    :selected_experiment,
    :generated_candidate,
    :sandbox_result,
    :certification_confidence,
    :uncertainty,
    :evidence,
    :lineage,
    requires_authorization: true
  ]

  @type t :: %__MODULE__{
               explanation_id: atom(),
               detected: String.t(),
               investigated: String.t() | nil,
               hypotheses: [String.t()],
               selected_experiment: %{id: atom()} | nil,
               generated_candidate: %{id: atom()} | nil,
               sandbox_result: %{status: atom()} | nil,
               certification_confidence: float() | nil,
               uncertainty: any() | nil,
               evidence: [String.t()],
               lineage: [atom()],
               requires_authorization: true
             }

  @doc """
  Builds an explanation from a decision package. `requires_authorization` is
  FORCED to true — deployment ALWAYS requires human authorization. This is a
  constitutional invariant, not a configuration option.
  """
  def build(package) do
    %__MODULE__{
      explanation_id: Map.get(package, :explanation_id, make_id()),
      detected: Map.get(package, :detected),
      investigated: Map.get(package, :investigated),
      hypotheses: Map.get(package, :hypotheses, []),
      selected_experiment: Map.get(package, :selected_experiment),
      generated_candidate: Map.get(package, :generated_candidate),
      sandbox_result: Map.get(package, :sandbox_result),
      certification_confidence: Map.get(package, :certification_confidence),
      uncertainty: Map.get(package, :uncertainty),
      evidence: Map.get(package, :evidence, []),
      lineage: Map.get(package, :lineage, []),
      requires_authorization: true
    }
  end

  @doc """
  Renders the explanation as the narrative arc the constitution requires:

      I detected X. I investigated X. These hypotheses explain it. This
      experiment has the highest expected information gain. I generated
      candidate Y. Y passed sandbox validation. Certification confidence is
      0.91. Deployment requires human authorization.
  """
  def render_narrative(%__MODULE__{} = e) do
    [
      "I detected #{e.detected}.",
      investigated_line(e),
      hypotheses_line(e),
      experiment_line(e),
      candidate_line(e),
      sandbox_line(e),
      confidence_line(e),
      uncertainty_line(e),
      evidence_line(e),
      lineage_line(e),
      "Deployment requires human authorization."
    ]
    |> Enum.reject(&is_nil/1)
    |> Enum.join("\n")
  end

  defp investigated_line(%{investigated: nil}), do: nil
  defp investigated_line(%{investigated: inv}), do: "I investigated #{inv}."

  defp hypotheses_line(%{hypotheses: []}), do: nil

  defp hypotheses_line(%{hypotheses: hyps}) do
    "These hypotheses explain it: #{Enum.map_join(hyps, "; ", & &1)}."
  end

  defp experiment_line(%{selected_experiment: nil}), do: nil

  defp experiment_line(%{selected_experiment: exp}) do
    "The selected experiment (#{inspect(exp.id)}) has the highest expected information gain."
  end

  defp candidate_line(%{generated_candidate: nil}), do: nil
  defp candidate_line(%{generated_candidate: c}), do: "I generated candidate #{inspect(c.id)}."

  defp sandbox_line(%{sandbox_result: nil}), do: nil

  defp sandbox_line(%{sandbox_result: %{status: :pass}}),
    do: "The candidate passed sandbox validation."

  defp sandbox_line(%{sandbox_result: %{status: status}}),
    do: "Sandbox validation status: #{inspect(status)}."

  defp confidence_line(%{certification_confidence: nil}), do: nil

  defp confidence_line(%{certification_confidence: c}),
    do: "Certification confidence is #{format_confidence(c)}."

  defp uncertainty_line(%{uncertainty: nil}), do: nil
  defp uncertainty_line(%{uncertainty: u}), do: "Uncertainty: #{inspect(u)}."

  defp evidence_line(%{evidence: []}), do: nil

  defp evidence_line(%{evidence: evs}) do
    formatted =
      Enum.map_join(evs, "; ", fn item ->
        text = to_string(item)
        truncated = String.slice(text, 0, 40)
        truncated <> if byte_size(text) > 40, do: "...", else: ""
      end)

    "Evidence: #{formatted}."
  end

  defp lineage_line(%{lineage: []}), do: nil

  defp lineage_line(%{lineage: path}) do
    "Lineage trace: #{Enum.map_join(path, " ← ", &to_string/1)}."
  end

  defp format_confidence(c) when is_float(c), do: Float.round(c, 2) |> to_string()
  defp format_confidence(c), do: to_string(c)

  defp make_id, do: :"expl-#{System.unique_integer([:monotonic])}"
end