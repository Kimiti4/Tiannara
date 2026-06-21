defmodule Tiannara.REA.Topo.ReplacementRegistry do
  @moduledoc """
  Tracks all active replacement proposals and their evaluation progress.
  """
  use GenServer

  alias Tiannara.REA.Topo.ReplacementProposal
  alias Tiannara.REA.Causal.CausalConstitution

  def start_link(opts \\ []), do: GenServer.start_link(__MODULE__, opts, name: __MODULE__)

  @spec submit(ReplacementProposal.t()) :: :ok
  def submit(%ReplacementProposal{} = p), do: GenServer.call(__MODULE__, {:submit, p})

  @spec all_active() :: [ReplacementProposal.t()]
  def all_active, do: GenServer.call(__MODULE__, :all_active)

  @spec for_target(binary()) :: [ReplacementProposal.t()]
  def for_target(channel_id), do: GenServer.call(__MODULE__, {:for_target, channel_id})

  @spec update_evaluation(binary(), float(), float()) :: :ok
  def update_evaluation(proposal_id, replacement_effect, baseline_effect),
    do: GenServer.call(__MODULE__, {:update, proposal_id, replacement_effect, baseline_effect})

  @spec promote_proven() :: [binary()]
  def promote_proven, do: GenServer.call(__MODULE__, :promote_proven)

  # --- Server ---

  @impl true
  def init(_), do: {:ok, %{proposals: %{}}}

  @impl true
  def handle_call({:submit, p}, _from, state),
    do: {:reply, :ok, %{state | proposals: Map.put(state.proposals, p.id, p)}}

  @impl true
  def handle_call(:all_active, _from, state),
    do: {:reply, Enum.filter(Map.values(state.proposals), &(&1.status == :testing)), state}

  @impl true
  def handle_call({:for_target, ch_id}, _from, state) do
    result = state.proposals |> Map.values() |> Enum.filter(&(&1.target_channel_id == ch_id && &1.status == :testing))
    {:reply, result, state}
  end

  @impl true
  def handle_call({:update, p_id, repl_eff, base_eff}, _from, state) do
    case Map.get(state.proposals, p_id) do
      nil -> {:reply, :ok, state}
      p ->
        updated = ReplacementProposal.evaluate(p, repl_eff, base_eff)
        {:reply, :ok, %{state | proposals: Map.put(state.proposals, p_id, updated)}}
    end
  end

  @impl true
  def handle_call(:promote_proven, _from, state) do
    proven = state.proposals |> Map.values() |> Enum.filter(&(&1.status == :proven))

    promoted_ids =
      Enum.flat_map(proven, fn p ->
        # NEW: Check proposer's lineage classification
        lineage_profile = Tiannara.REA.Epistemic.ReflexivityObservatory.classify(p.proposer_genome_id)
        classification = if lineage_profile, do: lineage_profile.classification, else: :unknown

        # Run epistemic audit (mocked for stateless registry)
        audit_result = run_audit(p.proposed_channel)

        cond do
          # PURE GAMER VETO: Automatically reject proposals from pure gamers,
          # regardless of their local "success" metrics.
          classification == :pure_gamer ->
            IO.puts("🛑 [REPLACEMENT REGISTRY] Vetoed proposal from pure_gamer lineage: #{p.proposer_genome_id}")
            failed = %{p | status: :failed, failure_reason: :pure_gamer_veto}
            Map.put(state.proposals, p.id, failed)
            []

          # INNOVATOR MULTIPLIER: High-trust promotion for innovators.
          classification == :innovator and audit_result.verdict == :grounded ->
            IO.puts("✅ [REPLACEMENT REGISTRY] High-trust promotion for innovator lineage: #{p.proposer_genome_id}")
            do_promote(p, state)
            [p.id]

          # STANDARD EVALUATION: For conservators or hybrids, require strict audit passing.
          audit_result.verdict == :grounded ->
            do_promote(p, state)
            [p.id]

          audit_result.verdict == :degraded ->
            extended = %{p | evaluation_windows: p.evaluation_windows - 25}
            Map.put(state.proposals, p.id, extended)
            []

          true ->
            failed = %{p | status: :failed, failure_reason: :epistemic_decoupling}
            Map.put(state.proposals, p.id, failed)
            []
        end
      end)

    # Clean up failed/promoted
    remaining =
      state.proposals
      |> Enum.reject(fn {_, p} -> p.status in [:failed, :promoted] end)
      |> Map.new()

    {:reply, promoted_ids, %{state | proposals: remaining}}
  end

  defp do_promote(p, state) do
    # Register the replacement channel in the graph
    Tiannara.REA.Causal.Graph.register(p.proposed_channel)
    # Register supersession in constitution
    CausalConstitution.register_supersession(p.target_channel_id, p.proposed_channel.id)
    # Attempt to supersede
    case CausalConstitution.supersede(p.target_channel_id) do
      :ok ->
        # Demote the original (disable it, but don't delete)
        case Tiannara.REA.Causal.Graph.all() |> Enum.find(&(&1.id == p.target_channel_id)) do
          nil -> nil
          orig ->
            disabled = %{orig | enabled: false}
            Tiannara.REA.Causal.Graph.register(disabled)
        end
      {:error, _} -> nil
    end
  end

  defp run_audit(_channel) do
    # Placeholder for actual audit against current global snapshot
    %{verdict: :grounded}
  end
end
