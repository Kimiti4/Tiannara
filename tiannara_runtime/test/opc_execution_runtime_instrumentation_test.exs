defmodule Tiannara.OPC.ExecutionRuntimeInstrumentationTest do
  use ExUnit.Case, async: false

  # Stage 3 (Council-authorized): the OPC ExecutionRuntime must mint canonical
  # forward_exec_v1 ids through the identity authority instead of producing a
  # local System.unique_integer. The producer has NO local authority over
  # execution_id; result keys and kernel bookkeeping are unchanged.
  # 5F-P1c/P3 correction (2026-10-19): the status VALUE is :simulated because
  # no compute occurs in ExecutionRuntime (placeholders only) — fabricated
  # execution must not be presented as real (see
  # certification/audit/PHASE_5F_STATUS_CORRECTION.md, C-04).

  alias Tiannara.OPC.Runtime.ExecutionRuntime
  alias TiannaraOS.Provenance.{IdentityAuthority, RuntimeContract}

  @producer "Tiannara.OPC.Runtime.ExecutionRuntime"
  @phase4 "Tiannara.Phase4.RealExecution"

  setup do
    tmp =
      Path.join([
        System.tmp_dir!(),
        "fp_opc_s3_#{System.system_time(:microsecond)}_#{System.unique_integer([:positive])}"
      ])

    File.rm_rf!(tmp)
    File.mkdir_p!(tmp)
    Application.put_env(:forward_provenance, :identity_authority_ledger_path, Path.join(tmp, "ledger.jsonl"))

    # mix test boots the application, so OPC.Supervisor has usually already
    # started the named ExecutionRuntime; fall back to starting it only when
    # absent (same guard as gpu_execution_quarantine_test.exs).
    case Process.whereis(ExecutionRuntime) do
      nil -> start_supervised!(ExecutionRuntime)
      pid when is_pid(pid) -> :ok
    end

    on_exit(fn ->
      Application.delete_env(:forward_provenance, :identity_authority_ledger_path)
      File.rm_rf!(tmp)
    end)

    :ok
  end

  test "execute mints a canonical authority-bound id and keeps the result shape" do
    shader = "kernel { observer(7) { measure } }"

    assert {:ok,
            %{
              observer: :observer_7,
              execution_id: id,
              shader_length: shader_length,
              allocated_node: "node_default",
              status: :simulated,
              execution_mode: :simulated
            }} = ExecutionRuntime.execute(:observer_7, shader)

    assert shader_length == byte_size(shader)
    assert id =~ ~r/^exec_[0-9]{13}_[0-9a-f-]{13}$/

    producer = @producer
    assert {:ok, %{"producer" => ^producer, "id_format" => "forward_exec_v1"}} = IdentityAuthority.resolve(id)
    assert {:ok, %{^id => %{observer: :observer_7, status: :simulated}}} = ExecutionRuntime.get_active_kernels()
  end

  test "two executes mint distinct canonical ids and both kernels are tracked" do
    assert {:ok, a} = ExecutionRuntime.execute(:observer_1, "kernel a")
    assert {:ok, b} = ExecutionRuntime.execute(:observer_2, "kernel b")
    assert a.execution_id != b.execution_id

    producer = @producer
    assert {:ok, %{"producer" => ^producer}} = IdentityAuthority.resolve(a.execution_id)
    assert {:ok, %{"producer" => ^producer}} = IdentityAuthority.resolve(b.execution_id)

    # The app-booted runtime is shared across the suite, so assert per-id
    # presence rather than an exact kernel count.
    assert {:ok, kernels} = ExecutionRuntime.get_active_kernels()
    assert Map.has_key?(kernels, a.execution_id)
    assert Map.has_key?(kernels, b.execution_id)
  end

  test "K at the OPC boundary: the minted id binds only to the OPC runtime" do
    assert {:ok, %{execution_id: id}} = ExecutionRuntime.execute(:observer_9, "kernel c")

    producer = @producer
    phase4 = @phase4

    assert {:ok, %{"producer" => ^producer}} = RuntimeContract.bind(id, producer)
    assert {:error, :substitution, _} = RuntimeContract.bind(id, phase4)
  end
end