defmodule TiannaraOS.Governance.Validation.Adapters.LedgerAdapter do
  @moduledoc """
  LedgerAdapter - Provides access to GovernanceLedger for validation campaigns.

  This adapter implements the LedgerAdapterBehaviour contract, providing
  canonical access to the immutable governance ledger.

  Responsibilities:
  - Query ledger entries by type and range
  - Compute ledger hash chain integrity
  - Extract canonical inputs for replay
  - Provide metadata about ledger state

  ## Archaeology

  - **purpose**: Provide read-only access to GovernanceLedger for validation campaigns
  - **introduced_in**: Phase 14.0.97
  - **depends_on**: TiannaraOS.Governance.GovernanceLedger
  - **constitution_reference**: GOVERNANCE_VALIDATION_CONSTITUTION.md Section 8.2
  - **owner**: Governance Council

  ## Usage

      {:ok, entries} = LedgerAdapter.query_ledger(:all)
      {:ok, hash_chain} = LedgerAdapter.verify_hash_chain()
      {:ok, inputs} = LedgerAdapter.extract_canonical_inputs()
  """

  @behaviour TiannaraOS.Governance.Validation.Adapter

  alias TiannaraOS.Governance.GovernanceLedger

  # Adapter behaviour implementation

  @impl true
  def execute(params) do
    case Map.get(params, :operation) do
      :query_ledger -> query_ledger(params)
      :verify_hash_chain -> verify_hash_chain()
      :extract_canonical_inputs -> extract_canonical_inputs()
      :get_metadata -> get_metadata()
      _ -> {:error, :unknown_operation}
    end
  end

  @impl true
  def measure(metric, _params \\ %{}) do
    case metric do
      :entry_count -> {:ok, count_entries()}
      :ledger_size -> {:ok, compute_ledger_size()}
      :hash_chain_integrity -> verify_hash_chain()
      _ -> {:error, :unknown_metric}
    end
  end

  @impl true
  def describe() do
    %{
      name: "LedgerAdapter",
      version: "1.0.0",
      purpose: "Provide read-only access to GovernanceLedger for validation campaigns",
      introduced_in: "Phase 14.0.97",
      depends_on: ["TiannaraOS.Governance.GovernanceLedger"],
      constitution_reference: "GOVERNANCE_VALIDATION_CONSTITUTION.md Section 8.2",
      owner: "Governance Council"
    }
  end

  @impl true
  def metadata() do
    %{
      module: __MODULE__,
      behaviour: TiannaraOS.Governance.Validation.Adapter,
      frozen_interface: true,
      hot_swappable: true,
      certified: false  # Will be set to true after certification in Phase 14.0.98
    }
  end

  # Private implementation functions

  defp query_ledger(%{type: type, from: from, to: to}) do
    # Query actual GovernanceLedger GenServer
    events = case {from, to} do
      {nil, nil} ->
        # Get all events of specified type
        if type == :all do
          GovernanceLedger.get_events()
        else
          GovernanceLedger.get_events_by_type(type)
        end
      {from_seq, nil} when is_integer(from_seq) ->
        # Get events from sequence number
        Enum.filter(GovernanceLedger.get_events(), &(&1.sequence_number >= from_seq))
      {nil, to_seq} when is_integer(to_seq) ->
        # Get events up to sequence number
        Enum.filter(GovernanceLedger.get_events(), &(&1.sequence_number <= to_seq))
      {from_seq, to_seq} when is_integer(from_seq) and is_integer(to_seq) ->
        # Get events in range
        Enum.filter(GovernanceLedger.get_events(), fn event ->
          event.sequence_number >= from_seq and event.sequence_number <= to_seq
        end)
    end
    
    {:ok, events}
  end

  defp query_ledger(%{type: type}) do
    query_ledger(%{type: type, from: nil, to: nil})
  end

  defp query_ledger(_params) do
    query_ledger(%{type: :all})
  end

  defp verify_hash_chain() do
    # Verify SHA-256 hash chain across all ledger entries
    events = GovernanceLedger.get_events()
    
    if Enum.empty?(events) do
      {:ok, %{integrity: :verified, algorithm: :sha256, entry_count: 0, valid: true}}
    else
      # Verify each event's previous_hash matches the hash of the previous event
      valid_chain = Enum.reduce_while(events, {true, nil}, fn event, {_valid, prev_hash} ->
        if prev_hash == nil or event.previous_hash == prev_hash do
          current_hash = compute_event_hash(event)
          {:cont, {true, current_hash}}
        else
          {:halt, {false, prev_hash}}
        end
      end)
      
      case valid_chain do
        {true, _} ->
          {:ok, %{integrity: :verified, algorithm: :sha256, entry_count: length(events), valid: true}}
        {false, _} ->
          {:error, %{integrity: :corrupted, algorithm: :sha256, entry_count: length(events), valid: false}}
      end
    end
  end

  defp extract_canonical_inputs() do
    # Extract minimal set of inputs needed for deterministic replay
    {:ok, %{
      ledger_version: "1.0.0",
      entry_count: count_entries(),
      hash_algorithm: :sha256
    }}
  end

  defp get_metadata() do
    {:ok, %{
      total_entries: count_entries(),
      size_bytes: compute_ledger_size(),
      first_entry_timestamp: DateTime.utc_now(),
      last_entry_timestamp: DateTime.utc_now()
    }}
  end

  defp count_entries() do
    # Query GovernanceLedger for actual count
    length(GovernanceLedger.get_events())
  end

  defp compute_ledger_size() do
    # Compute actual byte size of serialized ledger
    events = GovernanceLedger.get_events()
    events |> :erlang.term_to_binary() |> byte_size()
  end

  defp compute_event_hash(event) do
    # Compute SHA-256 hash of a single ledger event
    :crypto.hash(:sha256, :erlang.term_to_binary(event))
  end
end
