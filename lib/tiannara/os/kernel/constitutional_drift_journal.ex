defmodule TiannaraOS.Kernel.ConstitutionalDriftJournal do
  @moduledoc """
  ConstitutionalDriftJournal - Append-only immutable record of constitutional drift events.

  This journal records every execution's ConstitutionCertificate and detects
  any drift from previous executions by comparing manifests. It serves as the
  constitutional immune system's memory, tracking all changes to the constitutional
  substrate over time.

  ## Constitutional Role

  The drift journal ensures:
  1. Every execution is recorded with its certificate (not raw hashes)
  2. Drift is detected by comparing fingerprints referenced by certificates
  3. Unauthorized changes block execution
  4. Approved changes are tracked with governance metadata
  5. Complete audit trail of constitutional evolution

  ## Usage

      # Record execution with certificate
      cert = ConstitutionCertificate.generate(...)
      entry = ConstitutionalDriftJournal.record_execution("EXEC-001", cert)

      # Check for drift before execution
      fingerprint = ConstitutionFingerprint.compute(manifest)
      case ConstitutionalDriftJournal.check_drift(fingerprint) do
        :no_drift -> proceed_with_execution()
        {:drift_detected, entry} -> handle_drift(entry)
      end

      # Get drift history
      history = ConstitutionalDriftJournal.get_drift_history()
  """

  alias TiannaraOS.Kernel.ConstitutionManifest
  alias TiannaraOS.Kernel.ConstitutionCertificate
  alias TiannaraOS.Kernel.ConstitutionFingerprint

  @type drift_status :: :no_drift | :approved_change | :unauthorized_drift
  @type drift_severity :: :critical | :high | :medium | :low | :none
  @type drift_type :: :structural | :policy | :execution | :runtime | :documentation | :approved_migration | :none

  @type entry :: %__MODULE__{
    entry_id: String.t(),
    execution_id: String.t(),
    certificate_id: String.t(),
    timestamp: DateTime.t(),
    drift_detected: boolean(),
    drift_type: drift_type(),
    drift_severity: drift_severity(),
    changed_components: [atom()],
    approved: boolean(),
    result: :execution_allowed | :execution_blocked
  }

  defstruct [
    :entry_id,
    :execution_id,
    :certificate_id,
    :timestamp,
    :drift_detected,
    :drift_type,
    :drift_severity,
    :changed_components,
    :approved,
    :result
  ]

  @journal_table :constitutional_drift_journal

  @spec init() :: :ok
  def init() do
    :ets.new(@journal_table, [:ordered_set, :named_table, :public])
    :ok
  end

  @spec record_execution(String.t(), ConstitutionCertificate.t()) :: entry()
  def record_execution(execution_id, %ConstitutionCertificate{} = certificate) do
    previous_certificate = get_previous_certificate()

    {drift_detected, drift_type, drift_severity, changed_components, approved, result} =
      if is_nil(previous_certificate) do
        {false, :none, :none, [], true, :execution_allowed}
      else
        case compare_certificates(certificate, previous_certificate) do
          :no_drift ->
            {false, :none, :none, [], true, :execution_allowed}

            {:drift_detected, components} ->
              drift_type = classify_drift_type(components)
              severity = classify_drift_severity(components)
              approved = check_governance_approval(drift_type)
              result = if approved, do: :execution_allowed, else: :execution_blocked
              drift_status_type = if approved, do: :approved_change, else: :unauthorized_drift
              {true, drift_status_type, severity, components, approved, result}
        end
      end

    entry = %__MODULE__{
      entry_id: generate_entry_id(),
      execution_id: execution_id,
      certificate_id: certificate.certificate_id,
      timestamp: DateTime.utc_now(),
      drift_detected: drift_detected,
      drift_type: drift_type,
      drift_severity: drift_severity,
      changed_components: changed_components,
      approved: approved,
      result: result
    }

    :ets.insert(@journal_table, {entry.entry_id, entry})
    log_drift_event(entry)

    entry
  end

  @spec check_drift(ConstitutionFingerprint.t()) :: :no_drift | {:drift_detected, entry()}
  def check_drift(%ConstitutionFingerprint{} = current_fingerprint) do
    previous_certificate = get_previous_certificate()

    if is_nil(previous_certificate) do
      :no_drift
    else
      # Compare fingerprints directly
      if current_fingerprint.fingerprint == previous_certificate.fingerprint do
        :no_drift
      else
        # Drift detected - load manifests to classify type
        current_manifest = load_manifest(current_fingerprint.manifest_id)
        previous_manifest = load_manifest(previous_certificate.manifest_id)

        case ConstitutionManifest.compare(current_manifest, previous_manifest) do
            :no_drift ->
              :no_drift

            {:drift_detected, _components} ->
              temp_cert = %ConstitutionCertificate{
                certificate_id: "TEMP-CHECK-#{DateTime.utc_now() |> DateTime.to_iso8601()}",
                execution_id: "DRIFT-CHECK",
                manifest: current_manifest,
                combined_hash: current_manifest.combined_hash,
                generation_count: 0,
                started_at: DateTime.utc_now(),
                completed_at: DateTime.utc_now(),
                validation_status: :not_run,
                replay_status: :not_run,
                watchdog_status: :not_run,
                invariant_status: :not_checked,
                drift_journal_entries: [],
                certificate_hash: "",
                constitution_id: current_manifest.constitution_id,
                metadata: %{},
                fingerprint: current_fingerprint.fingerprint
              }

              entry = record_execution("DRIFT-CHECK-#{DateTime.utc_now() |> DateTime.to_iso8601()}", temp_cert)
              {:drift_detected, entry}
          end
      end
    end
  end

  @spec get_drift_history() :: [entry()]
  def get_drift_history() do
    :ets.tab2list(@journal_table)
    |> Enum.map(fn {_key, entry} -> entry end)
    |> Enum.sort_by(& &1.timestamp)
  end

  @spec get_drift_statistics() :: map()
  def get_drift_statistics() do
    history = get_drift_history()

    total_executions = length(history)
    drift_events = Enum.count(history, & &1.drift_detected)
    unauthorized_drifts = Enum.count(history, &(&1.drift_detected and not &1.approved))
    approved_changes = Enum.count(history, &(&1.drift_detected and &1.approved))

    %{
      total_executions: total_executions,
      drift_events: drift_events,
      unauthorized_drifts: unauthorized_drifts,
      approved_changes: approved_changes,
      drift_rate: if(total_executions > 0, do: drift_events / total_executions, else: 0.0)
    }
  end

  @spec format_report() :: String.t()
  def format_report() do
    history = get_drift_history()
    stats = get_drift_statistics()

    """
    ╔══════════════════════════════════════════════════════════╗
    ║         CONSTITUTIONAL DRIFT JOURNAL REPORT              ║
    ╚══════════════════════════════════════════════════════════╝

    Statistics:
      Total Executions:    #{stats.total_executions}
      Drift Events:        #{stats.drift_events}
      Unauthorized Drifts: #{stats.unauthorized_drifts}
      Approved Changes:    #{stats.approved_changes}
      Drift Rate:          #{Float.round(stats.drift_rate * 100, 2)}%

    Recent Entries:
    #{format_recent_entries(history)}
    """
  end

  # Private helpers

  @spec get_previous_certificate() :: ConstitutionCertificate.t() | nil
  defp get_previous_certificate() do
    history = get_drift_history()
    if length(history) > 0, do: List.last(history), else: nil
  end

  @spec compare_certificates(ConstitutionCertificate.t(), ConstitutionCertificate.t()) :: :no_drift | {:drift_detected, [atom()]}
  defp compare_certificates(%ConstitutionCertificate{} = current, %ConstitutionCertificate{} = previous) do
    current_manifest_id = current.manifest.manifest_id
    previous_manifest_id = previous.manifest.manifest_id
    
    if current_manifest_id == previous_manifest_id do
      :no_drift
    else
      {:drift_detected, [:manifest_changed]}
    end
  end

  @spec load_manifest(String.t()) :: ConstitutionManifest.t()
  defp load_manifest(_manifest_id), do: %ConstitutionManifest{}

  @spec classify_drift_type([atom()]) :: drift_type()
  defp classify_drift_type(components), do: ConstitutionManifest.classify_drift_type(components)

  @spec classify_drift_severity([atom()]) :: drift_severity()
  defp classify_drift_severity(components), do: ConstitutionManifest.classify_drift_severity(components)

  @spec check_governance_approval(drift_type()) :: boolean()
  defp check_governance_approval(:approved_migration), do: true
  defp check_governance_approval(_), do: false

  @spec generate_entry_id() :: String.t()
  defp generate_entry_id() do
    "ENTRY-#{:crypto.strong_rand_bytes(16) |> Base.encode16(case: :lower)}"
  end

  @spec log_drift_event(entry()) :: :ok
  defp log_drift_event(%__MODULE__{} = entry) do
    if entry.drift_detected do
      IO.puts("\n⚠️  DRIFT DETECTED:")
      IO.puts("   Entry ID: #{entry.entry_id}")
      IO.puts("   Certificate ID: #{entry.certificate_id}")
      IO.puts("   Drift Type: #{entry.drift_type}")
      IO.puts("   Severity: #{entry.drift_severity}")
      IO.puts("   Result: #{entry.result}")
    end
    :ok
  end

  @spec format_recent_entries([entry()]) :: String.t()
  defp format_recent_entries(entries) do
    entries
    |> Enum.take(-5)
    |> Enum.map(fn entry ->
      status_icon = if entry.drift_detected, do: "⚠️", else: "✅"
      "#{status_icon} #{entry.execution_id}: #{entry.drift_type} (#{entry.result})"
    end)
    |> Enum.join("\n")
  end
end
