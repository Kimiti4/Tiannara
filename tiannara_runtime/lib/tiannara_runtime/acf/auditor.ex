defmodule TiannaraRuntime.ACF.Auditor do
  @moduledoc """
  Axiomatic Conservation Framework auditor.

  Validates that a compiled meta‑op respects the invariant conservation
  axioms. The auditor works on a lightweight %InvariantTensor{} that
  captures the four core metrics required by the ACF:

  * `causal_flux` – coarse‑grained causal impact (derived from cost).
  * `information_delta` – net information loss (should be ~0).
  * `semantic_reversibility` – how well the operation can be reversed.
  * `compute_complexity` – estimated Kolmogorov‑like complexity.

  The constants below are the strict thresholds defined in the design.
  """

  @causal_floor 0.0
  @semantic_floor 0.92
  @complexity_ceiling 0.85

  defmodule InvariantTensor do
    @moduledoc false
    defstruct [:causal_flux, :information_delta, :semantic_reversibility, :compute_complexity]
  end

  @doc """
Validate a meta‑op map against the ACF axioms.

The function extracts the four metrics from the given `meta_op`
(fallback defaults are provided) and returns `:ok` if all thresholds
are satisfied or `{:reject, reason}` otherwise.
"""
  @spec audit(map()) :: :ok | {:reject, atom()}
  def audit(meta_op) when is_map(meta_op) do
    tensor = build_tensor(meta_op)

    result =
      cond do
        tensor.causal_flux < @causal_floor ->
          {:reject, :causal_violation}

        abs(tensor.information_delta) > 0.001 ->
          {:reject, :information_loss}

        tensor.semantic_reversibility < @semantic_floor ->
          {:reject, :semantic_corruption}

        tensor.compute_complexity > @complexity_ceiling ->
          {:reject, :runtime_overflow}

        true ->
          :ok
      end

    if Code.ensure_loaded?(TiannaraRuntime.ACF.StatsTracker) and Process.whereis(TiannaraRuntime.ACF.StatsTracker) do
      TiannaraRuntime.ACF.StatsTracker.record_audit(result)
    end

    result
  end

  defp build_tensor(meta_op) do
    # For now we derive simple proxies from the meta‑op fields.
    cost = Map.get(meta_op, :cost_estimate, 0)
    %InvariantTensor{
      causal_flux: cost,
      information_delta: 0.0,
      semantic_reversibility: 1.0,
      compute_complexity: cost
    }
  end
end
