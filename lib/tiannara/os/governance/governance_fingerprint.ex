defmodule TiannaraOS.Governance.GovernanceFingerprint do
  @moduledoc """
  GovernanceFingerprint - Cryptographic identity for governance state.

  Derived from GovernanceState + Ledger + InstitutionGraph + CapabilityGraph.
  Never manually constructed - always computed from canonical sources.

  This fingerprint serves as the unique identifier for a governance configuration,
  enabling archaeology to reference specific governance states unambiguously.

  ## Fingerprint Components

  ```
  Fingerprint = SHA-256(
    GovernanceState hash +
    GovernanceLedger hash +
    InstitutionGraph hash +
    CapabilityGraph hash +
    Timestamp
  )
  ```

  ## API

      @spec compute_fingerprint() :: t()
      @spec verify_fingerprint(t()) :: :valid | {:invalid, String.t()}
      @spec compare_fingerprints(t(), t()) :: :identical | {:diverged, map()}
  """

  defstruct [
    :fingerprint_id,
    :state_hash,
    :ledger_hash,
    :institution_graph_hash,
    :capability_graph_hash,
    :combined_hash,
    :timestamp,
    :metadata
  ]

  @type t :: %__MODULE__{
          fingerprint_id: String.t(),
          state_hash: String.t(),
          ledger_hash: String.t(),
          institution_graph_hash: String.t(),
          capability_graph_hash: String.t(),
          combined_hash: String.t(),
          timestamp: DateTime.t(),
          metadata: map()
        }

  @doc """
  Compute governance fingerprint from all canonical sources.

  This is the ONLY way to create a fingerprint - never manual construction.
  """
  @spec compute_fingerprint() :: t()
  def compute_fingerprint() do
    now = DateTime.utc_now()
    fingerprint_id = generate_fingerprint_id()

    # Capture governance state
    state = TiannaraOS.Governance.GovernanceState.capture_state()
    state_hash = compute_component_hash(state)

    # Get ledger hash
    ledger_events = TiannaraOS.Governance.GovernanceLedger.get_events()
    ledger_hash = compute_ledger_hash(ledger_events)

    # Get institution graph hash
    inst_graph = TiannaraOS.Governance.InstitutionGraph.init_standard_graph()
    inst_graph_hash = compute_component_hash(inst_graph)

    # Get capability graph hash
    cap_graph = TiannaraOS.Governance.CapabilityGraph.init_standard_graph()
    cap_graph_hash = compute_component_hash(cap_graph)

    # Compute combined hash
    combined_hash = compute_combined_hash(state_hash, ledger_hash, inst_graph_hash, cap_graph_hash, now)

    %__MODULE__{
      fingerprint_id: fingerprint_id,
      state_hash: state_hash,
      ledger_hash: ledger_hash,
      institution_graph_hash: inst_graph_hash,
      capability_graph_hash: cap_graph_hash,
      combined_hash: combined_hash,
      timestamp: now,
      metadata: %{
        total_institutions: map_size(state.institutions),
        total_appointments: map_size(state.appointments),
        total_ledger_events: length(ledger_events),
        fitness: state.fitness,
        entropy: state.entropy,
        health: state.health
      }
    }
  end

  @doc """
  Verify fingerprint matches current governance state.

  Recomputes fingerprint and compares against provided one.
  """
  @spec verify_fingerprint(t()) :: :valid | {:invalid, String.t()}
  def verify_fingerprint(%__MODULE__{} = original_fp) do
    current_fp = compute_fingerprint()

    if original_fp.combined_hash == current_fp.combined_hash do
      :valid
    else
      {:invalid, "Fingerprint mismatch - governance state has changed"}
    end
  end

  @doc """
  Compare two fingerprints to detect divergence.

  Returns detailed diff showing which components changed.
  """
  @spec compare_fingerprints(t(), t()) :: :identical | {:diverged, map()}
  def compare_fingerprints(%__MODULE__{} = fp1, %__MODULE__{} = fp2) do
    if fp1.combined_hash == fp2.combined_hash do
      :identical
    else
      diverged_components = []

      diverged_components =
        if fp1.state_hash != fp2.state_hash do
          diverged_components ++ [:governance_state]
        else
          diverged_components
        end

      diverged_components =
        if fp1.ledger_hash != fp2.ledger_hash do
          diverged_components ++ [:governance_ledger]
        else
          diverged_components
        end

      diverged_components =
        if fp1.institution_graph_hash != fp2.institution_graph_hash do
          diverged_components ++ [:institution_graph]
        else
          diverged_components
        end

      diverged_components =
        if fp1.capability_graph_hash != fp2.capability_graph_hash do
          diverged_components ++ [:capability_graph]
        else
          diverged_components
        end

      {:diverged, %{
        components: diverged_components,
        time_delta_seconds: DateTime.diff(fp2.timestamp, fp1.timestamp, :second),
        fp1_timestamp: DateTime.to_iso8601(fp1.timestamp),
        fp2_timestamp: DateTime.to_iso8601(fp2.timestamp)
      }}
    end
  end

  @doc """
  Export fingerprint for archaeological record.
  """
  @spec export_for_archaeology(t()) :: map()
  def export_for_archaeology(%__MODULE__{} = fp) do
    %{
      fingerprint_id: fp.fingerprint_id,
      combined_hash: fp.combined_hash,
      component_hashes: %{
        state: fp.state_hash,
        ledger: fp.ledger_hash,
        institution_graph: fp.institution_graph_hash,
        capability_graph: fp.capability_graph_hash
      },
      timestamp: DateTime.to_iso8601(fp.timestamp),
      metadata: fp.metadata
    }
  end

  @doc """
  Get fingerprint summary for dashboard display.
  """
  @spec get_summary(t()) :: map()
  def get_summary(%__MODULE__{} = fp) do
    %{
      fingerprint_id: fp.fingerprint_id,
      combined_hash_short: String.slice(fp.combined_hash, 0, 16),
      timestamp: DateTime.to_iso8601(fp.timestamp),
      institutions: fp.metadata.total_institutions,
      appointments: fp.metadata.total_appointments,
      ledger_events: fp.metadata.total_ledger_events,
      fitness: fp.metadata.fitness,
      entropy: fp.metadata.entropy,
      health: fp.metadata.health
    }
  end

  # Private helpers

  defp generate_fingerprint_id() do
    "gov-fingerprint-#{System.system_time(:millisecond)}-#{:erlang.unique_integer([:positive])}"
  end

  defp compute_component_hash(component) do
    hash_input = inspect(component, limit: :infinity, printable_limit: :infinity)
    :crypto.hash(:sha256, hash_input) |> Base.encode16(case: :lower)
  end

  defp compute_ledger_hash(events) do
    hash_input =
      events
      |> Enum.map(fn event -> event.current_hash end)
      |> Enum.join(":")

    :crypto.hash(:sha256, hash_input) |> Base.encode16(case: :lower)
  end

  defp compute_combined_hash(state_hash, ledger_hash, inst_hash, cap_hash, timestamp) do
    hash_input = "#{state_hash}:#{ledger_hash}:#{inst_hash}:#{cap_hash}:#{timestamp}"
    :crypto.hash(:sha256, hash_input) |> Base.encode16(case: :lower)
  end
end
