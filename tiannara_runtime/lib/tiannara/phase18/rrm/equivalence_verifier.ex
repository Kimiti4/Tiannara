defmodule Tiannara.Phase18.RRM.EquivalenceVerifier do
  @moduledoc """
  Verifies semantic preservation during rule metamorphosis.
  Enforces $\\| \\text{Exec}_{new} - \\text{Exec}_{old} \\|_2 < \\epsilon_{meta}$.

  Execution is modelled deterministically over the rule set, so the verdict is
  a function of the rules and never of chance:

    * Semantic rules (`:accumulator`, `:scale`, `:bias`, `:precision`) change
      *what* a surface computes and may therefore change the executed value.
    * Scheduling/codegen rules (`:unroll_factor`, `:vectorization`,
      `:cache_tiling`, `:branch_prediction`, `:kernel_layout`) change only *how*
      the work is scheduled and must leave the executed value untouched.

  A proposal that only re-tunes scheduling is therefore preserved, and a
  proposal that changes precision is rejected as a semantic divergence.
  """
  use GenServer

  @epsilon_meta 1.0e-5
  @sample_size 500

  @precision_decimals %{f16: 3, f32: 6, f64: 12}
  @default_precision_decimals 6

  def start_link(opts), do: GenServer.start_link(__MODULE__, opts, name: __MODULE__)

  @impl true
  def init(_opts), do: {:ok, %{verified_proposals: %{}}}

  @doc """
  Verifies that `new_rules` preserve the semantics of `old_rules`.

  Returns `{:ok, equiv_score}` when the maximum observed divergence is within
  `epsilon_meta`, otherwise `{:error, :divergence_detected}`.
  """
  @spec verify(proposal_id :: String.t(), old_rules :: map(), new_rules :: map()) ::
          {:ok, equiv_score :: float()} | {:error, :divergence_detected}
  def verify(proposal_id, old, new) do
    samples = Enum.map(1..@sample_size, fn index -> generate_test_input(old, index) end)

    diffs =
      Enum.map(samples, fn input ->
        abs(run_with_rules(new, input) - run_with_rules(old, input))
      end)

    max_diff = Enum.max(diffs)
    score = 1.0 - max_diff

    if max_diff <= @epsilon_meta do
      {:ok, score}
    else
      {:error, :divergence_detected}
    end
  end

  @doc "The equivalence tolerance enforced by this verifier."
  @spec epsilon_meta() :: float()
  def epsilon_meta, do: @epsilon_meta

  @doc "The number of deterministic samples used per verification."
  @spec sample_size() :: pos_integer()
  def sample_size, do: @sample_size

  @doc """
  Executes a rule set against a deterministic input vector.

  Exposed for testing and for replay: the same rules and input always produce
  the same value.
  """
  @spec run_with_rules(map(), list()) :: float()
  def run_with_rules(rules, input) do
    base = accumulate(Map.get(rules, :accumulator, :sum), input)
    scaled = base * numeric_or(Map.get(rules, :scale), 1.0) + numeric_or(Map.get(rules, :bias), 0.0)

    round_to(scaled, precision_decimals(rules))
  end

  # Deterministic sample vectors: reproducible across runs and machines.
  defp generate_test_input(rules, index) do
    size = max(length(Map.keys(rules)), 1)

    Enum.map(1..size, fn i ->
      :math.sin(i * 0.37 + index * 0.11)
    end)
  end

  defp accumulate(:sum, input), do: Enum.sum(input)
  defp accumulate(:mean, input), do: mean(input)
  defp accumulate(:max, input), do: Enum.max(input, fn -> 0.0 end)
  defp accumulate(_mode, input), do: Enum.sum(input)

  defp mean([]), do: 0.0
  defp mean(input), do: Enum.sum(input) / length(input)

  defp numeric_or(value, _default) when is_number(value), do: value
  defp numeric_or(_value, default), do: default

  defp precision_decimals(rules) do
    case Map.get(rules, :precision) do
      precision when is_atom(precision) ->
        Map.get(@precision_decimals, precision, @default_precision_decimals)

      _ ->
        @default_precision_decimals
    end
  end

  defp round_to(value, decimals) do
    factor = :math.pow(10, decimals)
    Float.round(value * factor) / factor
  end
end
