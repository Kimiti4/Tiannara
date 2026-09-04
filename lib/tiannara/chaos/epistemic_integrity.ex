defmodule Tiannara.Chaos.EpistemicIntegrity do
  @moduledoc """
  Verifies the core chaos invariant:

      "A subsystem failure must not silently destroy epistemic history."

  Compares a PRE-fault snapshot with a POST-recovery snapshot and fails hard
  if any epistemic artifact was silently destroyed.

  Reuses the Track B/C verification layers so a recovered system must STILL:
    * have no silently-lost pipeline items   (DiscoveryFunnel)
    * reconstruct full discovery provenance  (DiscoveryLedger)
  """

  alias Tiannara.Diagnostics.DiscoveryFunnel
  alias Tiannara.Diagnostics.EventSource.Mock
  alias Tiannara.Provenance.DiscoveryLedger

  @type snapshot :: %{
          required(:events) => list(),
          required(:checkpoints) => list(),
          required(:discovery_ids) => list()
        }

  @doc """
  Returns `{:intact, report}` or `{:violated, violations}`.

  Hard checks:
    * :silent_loss          -- an item present pre-fault is gone post-recovery
    * :broken_lineage       -- a checkpoint references a missing parent
    * :provenance_incomplete-- a discovery can no longer reconstruct its chain

  The funnel audit is included in the report as advisory context, since
  in-flight items may legitimately be `:pending` mid-fault.
  """
  def check(pre, post, _opts \\ []) do
    violations =
      check_no_silent_loss(pre.events, post.events) ++
        check_checkpoint_lineage(post.checkpoints) ++
        check_provenance_sample(post.events, post.discovery_ids)

    report = %{
      funnel_advisory: DiscoveryFunnel.audit(Mock.new(post.events)),
      violations: violations
    }

    case violations do
      [] -> {:intact, report}
      vs -> {:violated, vs}
    end
  end

  # --- hard check: no silent loss -----------------------------------------

  defp check_no_silent_loss(pre_events, post_events) do
    pre = stage_ids(pre_events)
    post = stage_ids(post_events)

    Enum.flat_map(pre, fn {stage, pre_set} ->
      post_set = Map.get(post, stage, MapSet.new())
      lost = MapSet.difference(pre_set, post_set)

      if MapSet.size(lost) > 0 do
        [%{kind: :silent_loss, stage: stage, lost: MapSet.to_list(lost)}]
      else
        []
      end
    end)
  end

  defp stage_ids(events) do
    Enum.reduce(events, %{}, fn
      {:created, stage, id, _}, acc ->
        Map.update(acc, stage, MapSet.new([id]), &MapSet.put(&1, id))

      _, acc ->
        acc
    end)
  end

  # --- hard check: checkpoint lineage -------------------------------------

  defp check_checkpoint_lineage(checkpoints) do
    ids = checkpoints |> Enum.map(& &1.id) |> MapSet.new()

    Enum.flat_map(checkpoints, fn cp ->
      case cp.parent do
        nil ->
          []

        parent ->
          if MapSet.member?(ids, parent) do
            []
          else
            [%{kind: :broken_lineage, checkpoint: cp.id, missing_parent: parent}]
          end
      end
    end)
  end

  # --- hard check: provenance reconstructability --------------------------

  defp check_provenance_sample(events, discovery_ids) do
    Enum.flat_map(discovery_ids, fn id ->
      ledger = DiscoveryLedger.reconstruct(id, events)

      case DiscoveryLedger.verdict(ledger) do
        :provenance_complete ->
          []

        {:provenance_incomplete, missing} ->
          [%{kind: :provenance_incomplete, discovery: id, missing: missing}]
      end
    end)
  end
end
