defmodule Tiannara.ASC.ProjectWorld.Constraint do
  @moduledoc """
  A non-functional constraint extracted from project requirements.

  Constraints are **measurable limits** the system must satisfy.
  They become the primary targets for load and performance test contracts.

  ## Examples

      "response time < 100ms (p99)"
      "throughput >= 10,000 req/s"
      "availability >= 99.9%"
      "data retention <= 90 days"

  ## Lifecycle

  Requirements.Extractor → ProjectWorld.constraints →
  Testing.Civilization (→ :load TestContract) →
  Observatory (recorded as performance baseline)
  """

  @derive Jason.Encoder

  defstruct [
    :id,
    :type,            # :latency | :throughput | :availability | :storage | :security | :compliance | :cost | :other
    :metric,          # the metric being constrained ("response_time", "availability")
    :operator,        # :lt | :lte | :gt | :gte | :eq
    :value,           # numeric or string value
    :unit,            # :ms | :s | :rps | :percent | :bytes | :days | nil
    :percentile,      # nil | 50 | 95 | 99 | 99.9
    :source_fragment,
    tags: []
  ]

  @type constraint_type ::
    :latency | :throughput | :availability | :storage
    | :security | :compliance | :cost | :other

  @type operator :: :lt | :lte | :gt | :gte | :eq

  @type t :: %__MODULE__{
    id: String.t(),
    type: constraint_type(),
    metric: String.t(),
    operator: operator(),
    value: number() | String.t(),
    unit: atom() | nil,
    percentile: number() | nil,
    source_fragment: String.t(),
    tags: [String.t()]
  }

  @spec new(constraint_type(), String.t(), operator(), number() | String.t(), keyword()) :: t()
  def new(type, metric, operator, value, opts \\ []) do
    %__MODULE__{
      id: "con_#{:erlang.unique_integer([:positive, :monotonic])}",
      type: type,
      metric: metric,
      operator: operator,
      value: value,
      unit: Keyword.get(opts, :unit),
      percentile: Keyword.get(opts, :percentile),
      source_fragment: Keyword.get(opts, :source_fragment, "#{metric} #{operator} #{value}"),
      tags: Keyword.get(opts, :tags, [])
    }
  end

  @doc "Format this constraint as a test assertion string."
  @spec to_test_assertion(t()) :: String.t()
  def to_test_assertion(%__MODULE__{} = c) do
    unit_str = if c.unit, do: " #{c.unit}", else: ""
    pct_str  = if c.percentile, do: " (p#{c.percentile})", else: ""
    "#{c.metric}#{pct_str} #{op_string(c.operator)} #{c.value}#{unit_str}"
  end

  # ---------------------------------------------------------------------------
  # Private
  # ---------------------------------------------------------------------------

  defp op_string(:lt),  do: "<"
  defp op_string(:lte), do: "<="
  defp op_string(:gt),  do: ">"
  defp op_string(:gte), do: ">="
  defp op_string(:eq),  do: "=="
end
