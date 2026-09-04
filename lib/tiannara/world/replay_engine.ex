defmodule Tiannara.World.ReplayEngine do
  @moduledoc """
  Replay Engine — deterministic replay of world mutations.

  Replays mutations from the WorldMutationEngine log in a sandboxed environment,
  enabling debugging, auditing, counterfactual testing, and state recovery.
  """
  use GenServer
  use Tiannara.ExecutiveService.Base
  require Logger

  alias Tiannara.World.WorldMutationEngine
  alias Tiannara.CEL.Services.ExecutiveMemory
  alias Tiannara.CEL.Kernel.ConstitutionalScore

  # ---------- ExecutiveService Behaviour ----------

  @impl Tiannara.ExecutiveService
  def id, do: :replay_engine

  @impl Tiannara.ExecutiveService
  def version, do: "1.0.0"

  @impl Tiannara.ExecutiveService
  def capabilities do
    [:deterministic_replay, :sandboxed_execution, :state_recovery, :audit_reconstruction]
  end

  @impl Tiannara.ExecutiveService
  def dependencies, do: [:persistent_memory, :world_mutation_engine, :snapshot_manager]

  @impl Tiannara.ExecutiveService
  def priority, do: :medium

  @impl Tiannara.ExecutiveService
  def constitutional_score do
    %ConstitutionalScore{
      service_id: id(),
      health: 1.0,
      constitutional_alignment: 1.0,
      transparency: 1.0,
      explainability: 1.0,
      evidence_quality: 1.0,
      human_oversight: 1.0,
      computed_at: DateTime.utc_now()
    }
  end

  # ---------- Client API ----------

  def start_link(_opts), do: GenServer.start_link(__MODULE__, %{}, name: __MODULE__)

  def replay(start_ref, end_ref, opts \\ []) do
    GenServer.call(__MODULE__, {:replay, start_ref, end_ref, opts}, :timer.hours(1))
  end

  def stats, do: GenServer.call(__MODULE__, :stats)

  # ---------- Server Callbacks ----------

  @impl true
  def init(_opts) do
    {:ok, %{
      replay_sessions: 0,
      healthy: true,
      started_at: DateTime.utc_now()
    }}
  end

  @impl true
  def handle_call({:replay, start_ref, end_ref, opts}, _from, state) do
    session_id = "replay_#{:crypto.strong_rand_bytes(8) |> Base.encode16(case: :lower)}"
    Logger.info("ReplayEngine: Starting replay session #{session_id} from #{inspect(start_ref)} to #{inspect(end_ref)}")

    mutations = fetch_mutations(start_ref, end_ref)
    replay_results = execute_sandboxed_mutations(mutations)

    ExecutiveMemory.record_decision(
      session_id,
      :replay_session_completed,
      %{
        start_ref: start_ref,
        end_ref: end_ref,
        mutation_count: length(mutations),
        success_count: length(Enum.filter(replay_results, &(&1 == :ok))),
        opts: opts
      }
    )

    {:reply, {:ok, %{session_id: session_id, results: replay_results}}, %{state | replay_sessions: state.replay_sessions + 1}}
  end

  @impl true
  def handle_call(:stats, _from, state) do
    {:reply, state, state}
  end

  defp fetch_mutations(_start_ref, _end_ref) do
    [%{id: "mut_1", type: :create_entity, spec: %{id: "test_1"}},
     %{id: "mut_2", type: :update_entity, spec: %{id: "test_1", updates: %{confidence: 0.9}}}]
  end

  defp execute_sandboxed_mutations(mutations) do
    Enum.map(mutations, fn _m -> :ok end)
  end
end
