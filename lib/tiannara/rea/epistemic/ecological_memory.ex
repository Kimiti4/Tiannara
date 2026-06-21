defmodule Tiannara.REA.Epistemic.EcologicalMemory do
  @moduledoc """
  Preserves topological configurations that historically exhibited
  high epistemic integrity, plus the failure signatures of topologies
  that collapsed into self-reinforcing (decoupled) states.
  
  Two registries:
    - Success Patterns: what healthy looked like
    - Failure Signatures: what decoupling looked like
  
  When the current topology shows early signs of replaying a past
  failure mode, the Observatory flags it.
  """
  use GenServer
  
  alias Tiannara.REA.Epistemic.Audit
  
  @type memory_entry :: %{
    id: binary(),
    topology_id: atom(),
    audit: Audit.audit_report(),
    epoch_recorded: non_neg_integer(),
    channel_snapshot: map(),
    ttl_epochs: non_neg_integer() | :infinite
  }
  
  @type failure_signature :: %{
    id: binary(),
    topology_id: atom(),
    pre_collapse_pattern: map(),
    collapse_epoch: non_neg_integer(),
    root_cause: atom()
  }
  
  def start_link(opts \\ []), do: GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  
  @spec record(Audit.audit_report(), map(), non_neg_integer()) :: :ok
  def record(%{verdict: verdict} = audit, channel_snapshot, epoch)
      when verdict in [:grounded, :degraded] do
    GenServer.call(__MODULE__, {:record_success, audit, channel_snapshot, epoch})
  end
  def record(_audit, _snapshot, _epoch), do: :ok
  
  @spec record_failure(atom(), map(), non_neg_integer(), atom()) :: :ok
  def record_failure(topology_id, pattern, epoch, root_cause) do
    GenServer.call(__MODULE__, {:record_failure, topology_id, pattern, epoch, root_cause})
  end
  
  @spec best_historical_topology() :: memory_entry() | nil
  def best_historical_topology, do: GenServer.call(__MODULE__, :best_success)
  
  @spec matches_past_failure?(map()) :: {boolean(), failure_signature() | nil}
  def matches_past_failure?(current_pattern),
    do: GenServer.call(__MODULE__, {:matches_failure, current_pattern})
  
  @spec all_successes() :: [memory_entry()]
  def all_successes, do: GenServer.call(__MODULE__, :all_successes)
  
  @spec all_failures() :: [failure_signature()]
  def all_failures, do: GenServer.call(__MODULE__, :all_failures)
  
  # --- Server ---
  
  @impl true
  def init(_), do: {:ok, %{successes: [], failures: []}}
  
  @impl true
  def handle_call({:record_success, audit, snapshot, epoch}, _from, state) do
    entry = %{
      id: generate_id(),
      topology_id: audit.topology_id,
      audit: audit,
      epoch_recorded: epoch,
      channel_snapshot: snapshot,
      ttl_epochs: 10_000
    }
    # Keep top 50 successes by integrity score
    updated = [entry | state.successes]
    |> Enum.sort_by(& &1.audit.epistemic_integrity, :desc)
    |> Enum.take(50)
    {:reply, :ok, %{state | successes: updated}}
  end
  
  @impl true
  def handle_call({:record_failure, topology_id, pattern, epoch, root_cause}, _from, state) do
    sig = %{
      id: generate_id(),
      topology_id: topology_id,
      pre_collapse_pattern: pattern,
      collapse_epoch: epoch,
      root_cause: root_cause
    }
    # Keep top 30 failure signatures
    updated = [sig | state.failures] |> Enum.take(30)
    {:reply, :ok, %{state | failures: updated}}
  end
  
  @impl true
  def handle_call(:best_success, _from, state) do
    result = case state.successes do
      [] -> nil
      ss -> hd(ss)
    end
    {:reply, result, state}
  end
  
  @impl true
  def handle_call(:all_successes, _from, state), do: {:reply, state.successes, state}
  @impl true
  def handle_call(:all_failures, _from, state), do: {:reply, state.failures, state}
  
  @impl true
  def handle_call({:matches_failure, current_pattern}, _from, state) do
    match = Enum.find(state.failures, fn sig ->
      pattern_similarity(current_pattern, sig.pre_collapse_pattern) > 0.75
    end)
    {:reply, {match != nil, match}, state}
  end

  @impl true
  def handle_call({:reset}, _from, _state), do: {:reply, :ok, %{successes: [], failures: []}}
  
  # Simple similarity: overlap of key metrics within 20% tolerance
  defp pattern_similarity(a, b) do
    keys = Map.keys(a) |> Enum.filter(&Map.has_key?(b, &1))
    if keys == [] do
      0.0
    else
      matches = Enum.count(keys, fn k ->
        av = Map.get(a, k, 0)
        bv = Map.get(b, k, 0)
        abs(av - bv) <= 0.2
      end)
      matches / length(keys)
    end
  end
  
  defp generate_id, do: :crypto.strong_rand_bytes(8) |> Base.encode16(case: :lower)
end
