defmodule TiannaraRuntime.CausalDiscovery.Behaviours.CausalReplay do
  @moduledoc """
  Phase 17.3 — CausalReplayBehaviour: contract for deterministic replay of causal discovery.
  """
  @callback replay_stage(
    stage :: atom(),
    config :: map(),
    evidence_set :: map()
  ) ::
    {:ok, map()}
    | {:error, String.t()}

  @callback replay_discovery(
    evidence_set :: map(),
    config :: map()
  ) ::
    {:ok, %{causal_graph: TiannaraRuntime.WorldModel.Ontology.CausalGraph.t(),
            causal_root: String.t()}}
    | {:error, String.t()}

  @callback verify_replay(
    model_id :: String.t(),
    version :: non_neg_integer()
  ) ::
    {:ok, %{verified: boolean(), mismatches: [String.t()]}}
    | {:error, String.t()}
end
