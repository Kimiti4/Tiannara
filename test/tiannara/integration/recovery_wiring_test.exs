defmodule Tiannara.Observatory.TelemetrySource.Mock do
  @moduledoc "Synthetic telemetry samples for recovery wiring tests."

  def synthetic(1.._ = range, funs) when is_map(funs) do
    Enum.map(range, fn i ->
      Map.new(funs, fn {key, fun} -> {key, fun.(i)} end)
    end)
  end
end

defmodule Tiannara.Integration.RecoveryWiringTest do
  use ExUnit.Case, async: false

  alias Tiannara.Integration.{ArtifactPaths, ReportGenerator, FinalReport}
  alias Tiannara.Soak.{RecoveryMatrix, RecoveryCertificate, Checkpoint, RecoveryGate}
  alias Tiannara.Soak.CheckpointStore.IsolatedFileStore
  alias Tiannara.Diagnostics.DiscoveryFunnel
  alias Tiannara.Observatory.TelemetrySource.Mock, as: TelemetryMock
  alias Tiannara.Memory.{IncidentDistiller, KnowledgeStore}

  @moduletag :recovery_wiring

  setup do
    base = Path.join(System.tmp_dir!(), "tiannara_wiring_#{System.unique_integer([:positive])}")
    File.mkdir_p!(base)
    on_exit(fn -> File.rm_rf!(base) end)
    {:ok, base: base, run_id: "run-" <> Base.encode16(:crypto.strong_rand_bytes(6), case: :lower)}
  end

  defp full_chain_events do
    ids = [:o1, :g1, :h1, :r1, :p1, :s1, :st1, :c1, :e1, :k1, :dc1, :vd1]
    tuples = Enum.zip(DiscoveryFunnel.stages(), ids)

    created =
      Enum.with_index(tuples)
      |> Enum.map(fn {{stage, id}, i} ->
        parents = if i == 0, do: [], else: [elem(Enum.at(tuples, i - 1), 1)]
        {:created, stage, id, parents}
      end)

    promoted =
      Enum.with_index(tuples)
      |> Enum.reject(fn {_, i} -> i == length(tuples) - 1 end)
      |> Enum.map(fn {{stage, id}, i} ->
        {_ns, next_id} = Enum.at(tuples, i + 1)
        {:disposition, stage, id, :promoted, next_id}
      end)

    created ++ promoted
  end

  defp build_environment(base, run_id) do
    funnel_path = Path.join(base, "funnel_events.etf")
    telemetry_path = Path.join(base, "telemetry.etf")
    checkpoint_dir = Path.join(base, "checkpoints")
    knowledge_dir = Path.join(base, "knowledge")
    attestation_path = Path.join(base, "recovery_attestation.etf")
    output_dir = Path.join(base, "report_out")

    File.write!(funnel_path, :erlang.term_to_binary(full_chain_events()))

    samples =
      TelemetryMock.synthetic(1..100, %{
        event_throughput: fn i -> i end,
        discovery_cycle_latency: fn i -> i end
      })

    File.write!(telemetry_path, :erlang.term_to_binary(samples))

    {:ok, cstore} = IsolatedFileStore.open(checkpoint_dir, run_id)

    for {elapsed, ts} <- [{3600, 1000}, {72 * 3600, 2000}] do
      cp =
        Checkpoint.new(%{
          soak_run_id: run_id,
          elapsed_seconds: elapsed,
          phase: :running,
          created_at: ts
        })

      :ok = cstore.__struct__.write(cstore, cp)
    end

    File.write!(attestation_path, :erlang.term_to_binary(RecoveryGate.required_checks()))

    {:ok, kstore} = KnowledgeStore.open(knowledge_dir)

    {:ok, artifact} =
      IncidentDistiller.distill(%{
        observation: "valid compound DETS records flagged corrupt",
        context: "soak checkpoint validation",
        evidence: "395/398 misclassified",
        cause: "wrong storage-schema assumption",
        recurrence: "395 instances",
        mechanism: "validity derived from key-shape",
        validation: "regression suite passes",
        principle: "derive validity from the storage contract"
      })

    :ok = KnowledgeStore.append_chain(kstore, [artifact])

    ArtifactPaths.new(run_id,
      funnel_events: funnel_path,
      telemetry: telemetry_path,
      checkpoint_dir: checkpoint_dir,
      knowledge_dir: knowledge_dir,
      recovery_attestation: attestation_path,
      output_dir: output_dir
    )
  end

  test "a passing recovery certificate makes the report recovery_verified",
       %{base: base, run_id: run_id} do
    paths = build_environment(base, run_id)

    results = RecoveryMatrix.run_all(Path.join(base, "recovery_matrix"))
    cert = RecoveryCertificate.issue(run_id, results)
    assert cert.all_passed

    report =
      ReportGenerator.generate(paths,
        run_start: 0,
        run_end: 72 * 3600,
        experiment_id: "exp-72h",
        recovery_certificate: cert
      )

    assert report.manifest.recovery_verified == true
    assert report.grade == :verified_pending_reproduction
    assert report.recovery_certificate.all_passed

    rendered = FinalReport.render(report)
    assert rendered =~ "RECOVERY CERTIFICATE"
    assert rendered =~ "9/9"
    assert rendered =~ "RECOVERY_VERIFIED"
    assert rendered =~ "VERIFIED_PENDING_REPRODUCTION"
  end

  test "a failing recovery certificate caps the grade at recovery_unverified",
       %{base: base, run_id: run_id} do
    paths = build_environment(base, run_id)

    results = RecoveryMatrix.run_all(Path.join(base, "recovery_matrix"))
    tampered = List.update_at(results, 0, &Map.put(&1, :passed, false))
    cert = RecoveryCertificate.issue(run_id, tampered)
    refute cert.all_passed

    report =
      ReportGenerator.generate(paths,
        run_start: 0,
        run_end: 72 * 3600,
        experiment_id: "exp-72h",
        recovery_certificate: cert
      )

    assert report.manifest.recovery_verified == false
    assert report.grade == :recovery_unverified
    assert :recovery_unverified in report.grade_reasons

    rendered = FinalReport.render(report)
    assert rendered =~ "RECOVERY_UNVERIFIED"
    assert rendered =~ "RECOVERY UNVERIFIED"
  end

  test "a certificate round-trips through save/load and is loadable from a path",
       %{base: base, run_id: run_id} do
    results = RecoveryMatrix.run_all(Path.join(base, "recovery_matrix"))
    cert = RecoveryCertificate.issue(run_id, results)

    cert_path = Path.join(base, "recovery_certificate.etf")
    :ok = RecoveryCertificate.save(cert, cert_path)

    assert {:ok, loaded} = RecoveryCertificate.load(cert_path)
    assert loaded.all_passed == cert.all_passed
    assert loaded.passed_count == cert.passed_count
    assert loaded.verdict == cert.verdict

    # And a report can pick it up via ArtifactPaths alone (no opt).
    paths = build_environment(base, run_id)
    paths = %{paths | recovery_certificate: cert_path}

    report =
      ReportGenerator.generate(paths, run_start: 0, run_end: 72 * 3600, experiment_id: "exp-72h")

    assert report.manifest.recovery_verified == true
  end
end