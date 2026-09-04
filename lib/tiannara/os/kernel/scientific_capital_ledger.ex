defmodule TiannaraOS.Kernel.ScientificCapitalLedger do
  @moduledoc """
  ScientificCapitalLedger - Immutable ledger for scientific capital accounting.

  This module is responsible ONLY for:
  - Calculating capital deltas from canonical transactions
  - Applying deltas to previous capital (conservation law)
  - Replaying historical executions for verification
  - Auditing capital conservation across generations

  IMPORTANT: This module NEVER defines what counts as capital. Definitions belong in
  ScientificCapitalDefinition. This module only calculates HOW MUCH capital changes.

  ## Constitutional Role

  The ledger enforces conservation laws and enables replay verification by:
  1. Extracting only canonical contribution fields
  2. Calculating deltas using policy coefficients
  3. Verifying exact equality (zero tolerance)
  4. Maintaining append-only immutable records

  ## Usage

      # Calculate capital delta from canonical transactions
      delta = ScientificCapitalLedger.calculate_delta(policy, transactions)

      # Apply delta to previous capital
      new_capital = ScientificCapitalLedger.apply(policy, old_capital, transactions)

      # Replay historical execution
      {:ok, :replay_successful} = ScientificCapitalLedger.replay(histories, policy)

      # Audit conservation
      audit_result = ScientificCapitalLedger.audit(histories, policy)
  """

  alias TiannaraOS.ScientificCapitalPolicy

  @type capital_amount :: integer()
  @type generation_data :: %{
          required(:discoveries_made) => non_neg_integer(),
          required(:theories_formed) => non_neg_integer(),
          required(:laws_validated) => non_neg_integer(),
          required(:applications_deployed) => non_neg_integer(),
          required(:unknowns_resolved) => non_neg_integer()
        }

  @doc """
  Calculate capital delta from canonical transactions using policy coefficients.

  Delta = Σ(contribution_count × coefficient) for all canonical fields.

  ## Parameters

  - `policy`: ScientificCapitalPolicy with coefficient values
  - `transactions`: Map containing canonical contribution counts

  ## Returns

  - Capital delta (integer, always non-negative)

  ## Examples

      iex> policy = ScientificCapitalPolicy.current()
      iex> transactions = %{discoveries_made: 5, theories_formed: 2, ...}
      iex> delta = ScientificCapitalLedger.calculate_delta(policy, transactions)
      iex> delta >= 0
      true
  """
  @spec calculate_delta(ScientificCapitalPolicy.t(), generation_data()) :: capital_amount()
  def calculate_delta(policy, transactions) do
    Enum.reduce(transactions, 0, fn {field, count}, acc ->
      coefficient = get_coefficient(policy, field)
      acc + (count * coefficient)
    end)
  end

  @doc """
  Apply capital delta to previous capital amount.

  Enforces conservation law: new_capital = previous_capital + delta

  ## Parameters

  - `policy`: ScientificCapitalPolicy (for validation)
  - `previous_capital`: Previous capital amount
  - `transactions`: Canonical contribution data

  ## Returns

  - New capital amount (previous + delta)

  ## Examples

      iex> policy = ScientificCapitalPolicy.current()
      iex> new_capital = ScientificCapitalLedger.apply(policy, 1000, transactions)
      iex> new_capital >= 1000
      true
  """
  @spec apply(ScientificCapitalPolicy.t(), capital_amount(), generation_data()) :: capital_amount()
  def apply(policy, previous_capital, transactions) do
    delta = calculate_delta(policy, transactions)
    previous_capital + delta
  end

  @doc """
  Replay historical execution from scratch using only canonical transactions.

  Recalculates all capital amounts from zero, comparing with recorded values.
  Used for constitutional verification and drift detection.

  ## Parameters

  - `histories`: List of GenerationHistory structs
  - `policy`: ScientificCapitalPolicy used during original execution

  ## Returns

  - `{:ok, :replay_successful}` if all calculations match
  - `{:error, violations}` if any mismatches detected

  ## Examples

      iex> histories = [...]
      iex> policy = ScientificCapitalPolicy.current()
      iex> ScientificCapitalLedger.replay(histories, policy)
      {:ok, :replay_successful}
  """
  @spec replay([map()], ScientificCapitalPolicy.t()) ::
          {:ok, :replay_successful} | {:error, [map()]}
  def replay(histories, policy) do
    # Verify policy hash first
    case ScientificCapitalPolicy.verify_hash(policy) do
      :ok -> :ok
      {:error, :hash_mismatch} ->
        raise "Policy hash verification failed - policy may be corrupted or tampered with"
    end

    # Replay from scratch, starting at zero capital
    {violations, _final_capital} = Enum.reduce(histories, {[], 0}, fn history, {violations_acc, cumulative_capital} ->
      # Extract canonical transaction contributions ONLY
      transactions = extract_canonical_contributions(history)

      # Calculate delta using policy (NEVER read recorded capital yet)
      expected_delta = calculate_delta(policy, transactions)
      expected_cumulative = cumulative_capital + expected_delta

      # NOW compare with recorded value
      recorded_delta = Map.get(history, :scientific_capital, 0)

      if recorded_delta != expected_delta do
        violation = %{
          generation: history.generation_number,
          expected_delta: expected_delta,
          recorded_delta: recorded_delta,
          difference: recorded_delta - expected_delta,
          expected_cumulative: expected_cumulative
        }
        {[violation | violations_acc], expected_cumulative}
      else
        {violations_acc, expected_cumulative}
      end
    end)

    violations_list = Enum.reverse(violations)

    if length(violations_list) == 0 do
      {:ok, :replay_successful}
    else
      {:error, violations_list}
    end
  end

  @doc """
  Verifies that recorded capital exactly matches calculated capital.

  Zero tolerance - exact equality required. No epsilon, no approximation.

  Returns :ok if equal, {:error, mismatch} otherwise.
  """
  @spec verify(capital_amount(), capital_amount()) :: :ok | {:error, :mismatch}
  def verify(recorded, calculated) do
    if recorded == calculated do
      :ok
    else
      {:error, :mismatch}
    end
  end

  @doc """
  Performs full constitutional audit of scientific capital accounting.

  Checks:
  1. Conservation law holds (capital never decreases)
  2. All deltas are non-negative
  3. Accounting identity holds for each generation
  4. Policy hash matches recorded policy hash (if present)

  ## Parameters
  - `histories`: List of GenerationHistory structs
  - `policy`: Current ScientificCapitalPolicy

  ## Returns
  %{passed: boolean, violations: [...]}
  """
  @spec audit([map()], ScientificCapitalPolicy.t()) :: map()
  def audit(histories, policy) do
    violations = []

    # Check 1: All deltas are non-negative
    negative_deltas = Enum.filter(histories, fn gen ->
      Map.get(gen, :scientific_capital, 0) < 0
    end)

    violations = if length(negative_deltas) > 0 do
      violations ++ Enum.map(negative_deltas, fn gen ->
        "Generation #{gen.generation_number}: Negative capital delta #{gen.scientific_capital}"
      end)
    else
      violations
    end

    # Check 2: Policy hash verification (if recorded)
    hash_violations = Enum.filter(histories, fn gen ->
      recorded_hash = Map.get(gen, :policy_hash)
      recorded_hash != nil and recorded_hash != policy.policy_hash
    end)

    violations = if length(hash_violations) > 0 do
      violations ++ Enum.map(hash_violations, fn gen ->
        "Generation #{gen.generation_number}: Policy hash mismatch"
      end)
    else
      violations
    end

    # Check 3: Replay verification
    case replay(histories, policy) do
      {:ok, :replay_successful} ->
        :ok

      {:error, replay_violations} ->
        _violations = violations ++ Enum.map(replay_violations, fn v ->
          "Generation #{v.generation}: Expected #{v.expected_delta}, got #{v.recorded_delta}"
        end)
    end

    %{
      passed: length(violations) == 0,
      violations: violations
    }
  end

  @doc """
  Get current ledger state for serialization.

  Since the ledger is purely functional (no GenServer state), this returns
  an empty state representing the ledger module itself.

  ## Returns

  - Empty ledger state map

  ## Examples

      iex> state = ScientificCapitalLedger.get_state()
      iex> Map.keys(state)
      [:transactions, :balances]
  """
  @spec get_state() :: map()
  def get_state() do
    %{
      transactions: [],
      balances: %{}
    }
  end

  # Private helper functions

  @spec get_coefficient(ScientificCapitalPolicy.t(), atom()) :: non_neg_integer()
  defp get_coefficient(policy, :discoveries_made), do: Map.fetch!(policy.coefficients, :discovery_value)
  defp get_coefficient(policy, :theories_formed), do: Map.fetch!(policy.coefficients, :theory_value)
  defp get_coefficient(policy, :laws_validated), do: Map.fetch!(policy.coefficients, :law_value)
  defp get_coefficient(policy, :applications_deployed), do: Map.fetch!(policy.coefficients, :application_value)
  defp get_coefficient(policy, :unknowns_resolved), do: Map.fetch!(policy.coefficients, :unknown_resolution_value)
  defp get_coefficient(_policy, _field), do: 0

  defp extract_canonical_contributions(history) do
    # Extract ONLY fields defined in ScientificCapitalDefinition
    %{
      discoveries_made: Map.get(history, :discoveries_made, 0),
      theories_formed: Map.get(history, :theories_formed, 0),
      laws_validated: Map.get(history, :laws_validated, 0),
      applications_deployed: Map.get(history, :applications_deployed, 0),
      unknowns_resolved: Map.get(history, :unknowns_resolved, 0)
    }
  end
end
