defmodule Tiannara.Chaos.Blueprint do
  @moduledoc """
  The full chaos campaign catalog (Track E).

  Every fault carries the expected trajectory:

      Fault -> Detection -> Containment -> Recovery ->
      Evidence preservation -> Service restoration -> Verification

  Governing invariant:

      A subsystem failure must not silently destroy epistemic history.

  This blueprint is a specification. It never executes against the live
  72h soak. Post-soak, it is driven against an ISOLATED instance via
  `Tiannara.Chaos.Runner`.
  """

  alias Tiannara.Chaos.Fault

  @lifecycle_phases [
    :fault_injected,
    :detected,
    :contained,
    :recovery_started,
    :evidence_preserved,
    :service_restored,
    :verified
  ]

  def lifecycle_phases, do: @lifecycle_phases

  @doc "The full catalog of required faults."
  def all do
    [
      Fault.new(:executive_memory_unavailable, :executive_memory, :dependency_outage,
        detection: [:health_probe_timeout, :circuit_breaker_open],
        containment: [:isolate_memory_calls, :serve_degraded_read_only],
        recovery: [:restart_subsystem, :replay_from_last_stable_checkpoint],
        evidence_preservation: [:append_degradation_event_to_audit_log, :preserve_pre_fault_checkpoints],
        verification: [:epistemic_integrity_check, :memory_read_after_restore]
      ),

      Fault.new(:event_store_unavailable, :event_store, :dependency_outage,
        detection: [:write_ack_timeout, :heartbeat_loss],
        containment: [:buffer_events_to_durable_outbox, :stop_advancing_discovery_pipeline],
        recovery: [:reconnect_with_backoff, :replay_buffered_events_in_order],
        evidence_preservation: [:outbox_is_durable, :no_event_dropped_silently],
        verification: [:event_continuity_check, :funnel_audit_no_silent_loss]
      ),

      Fault.new(:discovery_scheduler_unavailable, :discovery_scheduler, :dependency_outage,
        detection: [:no_schedule_heartbeat, :queue_stall],
        containment: [:freeze_experiment_admission, :keep_observations_flowing],
        recovery: [:restart_scheduler, :rehydrate_pending_queue_from_journal],
        evidence_preservation: [:record_scheduling_gap_window],
        verification: [:funnel_audit_dispositions_explained]
      ),

      Fault.new(:unified_world_model_unavailable, :unified_world_model, :dependency_outage,
        detection: [:query_timeout, :model_health_probe_failure],
        containment: [:fallback_to_last_valid_model_snapshot],
        recovery: [:reload_model, :validate_checksum_before_use],
        evidence_preservation: [:log_model_fallback_usage],
        verification: [:prediction_consistency_check]
      ),

      Fault.new(:experiment_worker_crash, :experiment_worker, :process_crash,
        detection: [:process_exit_signal, :supervisor_child_termination],
        containment: [:mark_experiment_incomplete, :quarantine_partial_results],
        recovery: [:supervisor_restart, :resume_or_retry_with_idempotency_key],
        evidence_preservation: [:preserve_partial_evidence_with_crash_context],
        verification: [:no_duplicate_evidence, :provenance_reconstructable]
      ),

      Fault.new(:nats_unavailable, :nats, :dependency_outage,
        detection: [:connection_lost, :publish_failure],
        containment: [:queue_messages_to_durable_outbox, :circuit_break],
        recovery: [:reconnect_with_backoff, :replay_queued_messages],
        evidence_preservation: [:durable_outbox],
        verification: [:delivery_exactly_once_or_idempotent]
      ),

      Fault.new(:jetstream_unavailable, :jetstream, :dependency_outage,
        detection: [:stream_ack_timeout],
        containment: [:pause_consumers, :buffer_producers],
        recovery: [:restore_stream, :replay_from_last_seq],
        evidence_preservation: [:stream_seq_continuity],
        verification: [:no_message_loss, :no_undocumented_gap]
      ),

      Fault.new(:postgresql_unavailable, :postgresql, :dependency_outage,
        detection: [:connection_refused, :transaction_timeout],
        containment: [:enter_read_only_mode, :queue_writes],
        recovery: [:reconnect, :replay_queued_transactions],
        evidence_preservation: [:wal_durability, :write_ahead_journal],
        verification: [:transaction_atomicity_check]
      ),

      Fault.new(:redis_unavailable, :redis, :dependency_outage,
        detection: [:ping_timeout],
        containment: [:fallback_to_db_backed_or_no_cache],
        recovery: [:reconnect, :warm_cache_lazily],
        evidence_preservation: [:cache_is_derived_data_only, :no_source_of_truth_in_redis],
        verification: [:no_epistemic_data_lost]
      ),

      Fault.new(:dets_corruption, :dets, :data_corruption,
        description: "Echoes the real CorruptionDetector incident: validity must derive from the storage contract, not key-shape assumptions.",
        detection: [:checksum_mismatch, :open_failure],
        containment: [:quarantine_corrupt_table, :stop_writes_to_it],
        recovery: [:restore_from_last_verified_snapshot, :replay_journal],
        evidence_preservation: [:preserve_corrupt_file_for_forensics, :record_detector_verdict],
        verification: [:record_reclassification_regression, :funnel_audit]
      ),

      Fault.new(:checkpoint_corruption, :checkpoint, :data_corruption,
        detection: [:checkpoint_checksum_failure],
        containment: [:fall_back_to_previous_good_checkpoint],
        recovery: [:rebuild_from_lineage, :replay_since_last_good_checkpoint],
        evidence_preservation: [:checkpoint_lineage_unbroken, :preserve_corrupt_checkpoint],
        verification: [:lineage_walk_succeeds]
      ),

      Fault.new(:network_partition, :cluster, :network,
        detection: [:split_brain_detection, :peer_unreachable],
        containment: [:pause_writes_on_minority_side, :fence],
        recovery: [:merge_or_resync_per_consensus_policy],
        evidence_preservation: [:record_partition_boundary_and_duration],
        verification: [:no_conflicting_epistemic_state_silently_merged]
      ),

      Fault.new(:message_duplication, :message_bus, :protocol,
        detection: [:duplicate_seq_observed],
        containment: [:idempotent_consumer],
        recovery: [:deduplicate_by_idempotency_key],
        evidence_preservation: [:log_duplicate_count],
        verification: [:exactly_once_effect, :funnel_counts_not_inflated]
      ),

      Fault.new(:message_reordering, :message_bus, :protocol,
        detection: [:out_of_order_seq],
        containment: [:reorder_buffer_with_watermark],
        recovery: [:apply_in_logical_order],
        evidence_preservation: [:record_reorder_depth],
        verification: [:causal_order_preserved_in_event_log]
      ),

      Fault.new(:slow_consumer, :message_bus, :performance,
        detection: [:consumer_lag_exceeds_threshold],
        containment: [:apply_backpressure, :shed_non_critical_load],
        recovery: [:scale_consumer_or_increase_batch],
        evidence_preservation: [:record_lag_curve],
        verification: [:no_message_dropped_due_to_lag]
      ),

      Fault.new(:process_restart, :runtime, :lifecycle,
        detection: [:process_monitor_down],
        containment: [:supervisor_restart_strategy],
        recovery: [:reinit_from_durable_state_only],
        evidence_preservation: [:no_in_memory_only_state_is_epistemic],
        verification: [:state_reconstructed_from_persistent_store]
      ),

      Fault.new(:supervisor_restart, :runtime, :lifecycle,
        detection: [:supervisor_restart_event],
        containment: [:children_restart_in_order],
        recovery: [:rebuild_supervision_tree, :rehydrate_children],
        evidence_preservation: [:record_restart_intensity],
        verification: [:epistemic_integrity_check]
      )
    ]
  end

  def count, do: length(all())

  def get(id), do: Enum.find(all(), &(&1.id == id))
end
