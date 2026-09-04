defmodule Tiannara.Discovery.Quality.Domain do
  defmodule QualityReport do
    defstruct [:id, :discovery_id, :overall_score, :checks, :warnings, :violations, :recommendation, :assessed_at]

    @type t :: %__MODULE__{}

    @recommendations [:pass, :pass_with_warnings, :revise, :reject]
    def recommendations, do: @recommendations

    def new(attrs) do
      %__MODULE__{
        id: "qa_#{:crypto.strong_rand_bytes(8) |> Base.encode16(case: :lower)}",
        checks: [], warnings: [], violations: [], assessed_at: DateTime.utc_now()
      }
      |> struct(attrs)
    end
  end

  defmodule QualityCheck do
    defstruct [:name, :category, :passed, :score, :details, :evidence]

    @type t :: %__MODULE__{}

    @categories [
      :confirmation_bias, :monoculture, :circular_reasoning,
      :evidence_contamination, :statistical_anomaly, :completeness,
      :falsifiability, :reproducibility
    ]
    def categories, do: @categories

    def new(attrs) do
      %__MODULE__{evidence: []} |> struct(attrs)
    end
  end
end
