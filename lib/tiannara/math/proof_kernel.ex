defmodule Tiannara.Math.ProofKernel do
  @moduledoc """
  Small deterministic proof-checking kernel.

  The kernel checks proof steps against explicit inference rules. It does not
  search for proofs, call an LLM, or trust a claimed theorem status.

  Supported fragment:
    * propositional atoms;
    * equality propositions;
    * implication;
    * conjunction;
    * reflexivity;
    * assumption;
    * conjunction introduction/elimination;
    * implication elimination (modus ponens).

  A successful check means the conclusion follows in this kernel's formal
  fragment from the supplied assumptions. It does not establish that external
  modelling assumptions describe reality.
  """

  @type term :: {:atom, atom()} | {:const, term()} | {:var, atom()}
  @type proposition ::
          {:atom, atom()}
          | {:eq, term(), term()}
          | {:and, proposition(), proposition()}
          | {:imp, proposition(), proposition()}

  @type step :: %{
          required(:id) => pos_integer(),
          required(:rule) => atom(),
          optional(:refs) => [pos_integer()],
          optional(:proposition) => proposition(),
          optional(:term) => term()
        }

  @spec check([proposition()], proposition(), [step()]) ::
          {:ok, map()} | {:error, term()}
  def check(assumptions, conclusion, steps)
      when is_list(assumptions) and is_list(steps) do
    with :ok <- validate_propositions(assumptions),
         :ok <- validate_proposition(conclusion),
         :ok <- validate_steps(steps),
         {:ok, context} <- replay(steps, assumptions),
         :ok <- require_conclusion(context, conclusion) do
      {:ok, %{
        status: :proven_under_assumptions,
        assumptions: assumptions,
        conclusion: conclusion,
        checked_steps: length(steps),
        kernel: "Tiannara.Math.ProofKernel.v1",
        certification_eligible: false,
        external_reality_claim: :not_established
      }}
    end
  end

  def check(_, _, _), do: {:error, :invalid_proof_input}

  defp replay(steps, assumptions) do
    Enum.reduce_while(steps, {:ok, %{assumptions: MapSet.new(assumptions), steps: %{}}}, fn step, {:ok, ctx} ->
      case check_step(step, ctx) do
        {:ok, proposition} ->
          {:cont, {:ok, %{ctx | steps: Map.put(ctx.steps, step.id, proposition)}}}

        {:error, reason} ->
          {:halt, {:error, {:invalid_step, step.id, reason}}}
      end
    end)
  end

  defp check_step(%{rule: :assumption, proposition: proposition}, ctx) do
    if MapSet.member?(ctx.assumptions, proposition), do: {:ok, proposition},
      else: {:error, :assumption_not_supplied}
  end

  defp check_step(%{rule: :reflexivity, proposition: {:eq, a, b}}, _ctx) do
    if a == b, do: {:ok, {:eq, a, b}}, else: {:error, :reflexivity_requires_identical_terms}
  end

  defp check_step(%{rule: :and_intro, refs: [a, b], proposition: proposition}, ctx) do
    with {:ok, left} <- ref(ctx, a),
         {:ok, right} <- ref(ctx, b),
         {:ok, ^proposition} <- exact({:and, left, right}, proposition) do
      {:ok, proposition}
    end
  end

  defp check_step(%{rule: :and_elim_left, refs: [ref_id], proposition: proposition}, ctx) do
    with {:ok, {:and, left, _right}} <- ref(ctx, ref_id),
         {:ok, ^proposition} <- exact(left, proposition) do
      {:ok, proposition}
    else
      _ -> {:error, :left_conjunction_elimination_failed}
    end
  end

  defp check_step(%{rule: :and_elim_right, refs: [ref_id], proposition: proposition}, ctx) do
    with {:ok, {:and, _left, right}} <- ref(ctx, ref_id),
         {:ok, ^proposition} <- exact(right, proposition) do
      {:ok, proposition}
    else
      _ -> {:error, :right_conjunction_elimination_failed}
    end
  end

  defp check_step(%{rule: :imp_elim, refs: [imp_id, arg_id], proposition: proposition}, ctx) do
    with {:ok, {:imp, antecedent, consequent}} <- ref(ctx, imp_id),
         {:ok, arg} <- ref(ctx, arg_id),
         :ok <- exact(antecedent, arg),
         :ok <- exact(consequent, proposition) do
      {:ok, proposition}
    else
      _ -> {:error, :implication_elimination_failed}
    end
  end

  defp check_step(_, _), do: {:error, :unsupported_or_malformed_rule}

  defp ref(ctx, id) when is_integer(id) do
    case Map.fetch(ctx.steps, id) do
      {:ok, value} -> {:ok, value}
      :error -> {:error, :unknown_reference}
    end
  end

  defp exact(a, a), do: :ok
  defp exact(_, _), do: {:error, :proposition_mismatch}

  defp require_conclusion(ctx, conclusion) do
    if Enum.any?(Map.values(ctx.steps), &(&1 == conclusion)),
      do: :ok,
      else: {:error, :conclusion_not_derived}
  end

  defp validate_steps(steps) do
    ids = Enum.map(steps, &Map.get(&1, :id))
    cond do
      Enum.any?(ids, &(not is_integer(&1) or &1 <= 0)) -> {:error, :invalid_step_ids}
      length(ids) != MapSet.size(MapSet.new(ids)) -> {:error, :duplicate_step_id}
      true -> :ok
    end
  end

  defp validate_propositions(values) when is_list(values) do
    Enum.reduce_while(values, :ok, fn value, :ok ->
      case validate_proposition(value) do
        :ok -> {:cont, :ok}
        {:error, reason} -> {:halt, {:error, reason}}
      end
    end)
  end

  defp validate_proposition(value) do
    case value do
      {:atom, a} when is_atom(a) -> :ok
      {:eq, a, b} -> validate_term(a, b)
      {:and, a, b} -> validate_proposition(a) |> combine(validate_proposition(b))
      {:imp, a, b} -> validate_proposition(a) |> combine(validate_proposition(b))
      _ -> {:error, :invalid_proposition}
    end
  end

  defp validate_term(a, b) do
    if valid_term?(a) and valid_term?(b), do: :ok, else: {:error, :invalid_term}
  end

  defp valid_term?({:var, a}) when is_atom(a), do: true
  defp valid_term?({:const, value}), do: valid_term?(value)
  defp valid_term?({:atom, a}) when is_atom(a), do: true
  defp valid_term?(_), do: false

  defp combine(:ok, :ok), do: :ok
  defp combine({:error, e}, _), do: {:error, e}
  defp combine(_, {:error, e}), do: {:error, e}
end
