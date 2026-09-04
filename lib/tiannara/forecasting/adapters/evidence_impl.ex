defmodule Tiannara.Forecasting.Adapters.EvidenceImpl do
  @moduledoc """
  D2 concrete implementation of `Tiannara.Forecasting.Adapters.Evidence`.

  Links signals to existing evidence entities by id without creating a parallel
  evidence ontology. The linkage is recorded as a bounded testimonial map; the
  actual evidence authority lives in the existing evidence infrastructure.

  Linkage records are stored in an ETS `:set` (`:efdi_evidence_links`) so the
  same signal can be linked to multiple evidence ids and retrieved deterministically.
  """

  @behaviour Tiannara.Forecasting.Adapters.Evidence

  @table :efdi_evidence_links

  alias Tiannara.Forecasting.{Signal, SignalRegistry}
  alias Tiannara.Forecasting.Adapters.Evidence

  def ensure_table! do
    if :ets.info(@table) == :undefined do
      :ets.new(@table, [:set, :public, :named_table, read_concurrency: true])
    end
    :ok
  end

  @impl Evidence
  @spec link_to_evidence(Signal.t(), String.t(), :supports | :contradicts) ::
          {:ok, map()} | {:error, term()}
  def link_to_evidence(%Signal{} = signal, evidence_id, kind)
      when kind in [:supports, :contradicts] do
    ensure_table!()
    link = %{
      signal_id: signal.id,
      evidence_id: evidence_id,
      kind: kind,
      linked_at: DateTime.utc_now()
    }
    :ets.insert(@table, {{signal.id, evidence_id}, link})
    {:ok, link}
  end

  def link_to_evidence(_, _, _), do: {:error, :invalid_kind}

  @impl Evidence
  @spec evidence_for(Signal.t()) :: {:ok, [map()]} | {:error, term()}
  def evidence_for(%Signal{} = signal) do
    ids = linked_evidence_ids(signal.id)
    ids = if is_binary(signal.observation_ref) and signal.observation_ref not in ids,
             do: [signal.observation_ref | ids], else: ids
    {:ok, Enum.map(ids, &%{evidence_id: &1, linked: true})}
  end

  @doc "Resolves evidence refs for a signal id via the registry."
  def evidence_for_id(signal_id) when is_binary(signal_id) do
    case SignalRegistry.get(signal_id) do
      {:ok, s} -> evidence_for(s)
      :error -> {:error, :signal_not_found}
    end
  end

defp linked_evidence_ids(signal_id) do
    ensure_table!()
    :ets.select(@table, [{{{signal_id, :"$1"}, :_}, [], [:"$1"]}])
  end
end