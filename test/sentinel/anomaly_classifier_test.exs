defmodule Tiannara.Sentinel.AnomalyClassifierTest do
  use ExUnit.Case, async: false

  alias Tiannara.Sentinel.AnomalyClassifier

  describe "AnomalyClassifier" do
    test "classify with empty observations returns empty" do
      assert AnomalyClassifier.classify([], []) == []
    end

    test "classify detects memory threshold crossing" do
      obs = [%{type: :memory_pressure, value: %{total_bytes: 5_000_000_000}, timestamp: DateTime.utc_now()}]
      anomalies = AnomalyClassifier.classify(obs, [])
      memory_anomalies = Enum.filter(anomalies, fn a -> a.domain == :memory end)
      assert length(memory_anomalies) > 0
      assert hd(memory_anomalies).severity == :critical
    end

    test "classify detects process threshold" do
      obs = [%{type: :vm_health, value: %{process_count: 250_000, process_limit: 262_144, atom_count: 500_000, atom_limit: 1_048_576, run_queue: 1}, timestamp: DateTime.utc_now()}]
      anomalies = AnomalyClassifier.classify(obs, [])
      process_anomalies = Enum.filter(anomalies, fn a -> a.domain == :process end)
      assert length(process_anomalies) > 0
    end

    test "classify detects run queue anomaly" do
      obs = [%{type: :vm_health, value: %{process_count: 100, process_limit: 262_144, atom_count: 100_000, atom_limit: 1_048_576, run_queue: 50}, timestamp: DateTime.utc_now()}]
      anomalies = AnomalyClassifier.classify(obs, [])
      perf_anomalies = Enum.filter(anomalies, fn a -> a.domain == :performance end)
      assert length(perf_anomalies) > 0
    end

    test "total_detected returns count" do
      assert is_integer(AnomalyClassifier.total_detected())
    end

    test "status returns classifier info" do
      status = AnomalyClassifier.status()
      assert Map.has_key?(status, :active_anomalies)
      assert Map.has_key?(status, :total_detected)
      assert Map.has_key?(status, :last_classification_at)
    end
  end
end
