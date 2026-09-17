defmodule Tiannara.Phase4.RealExecutionInstrumentationTest do
  use ExUnit.Case, async: false

  # Stage 3 (Council-authorized) runtime instrumentation integration suite.
  # Every execution that leaves the Phase-4 producer must be authority-MINTED
  # and lifecycle-normalized BEFORE the sandbox runs; a failed sandbox must
  # STILL yield a canonical (failed) attribution while the experiment-facing
  # return values stay unchanged. K/L/terminal guarantees are additionally
  # re-checked at this boundary using the real module's minted id.

  alias Tiannara.Phase4.RealExecution
  alias Tiannara.Omega.HumanDelivery.Authorization
  alias Tiannara.SelfImprovement.Sandbox.{BenchmarkSpec, CodePatch, TestSpec}
  alias TiannaraOS.Provenance.{IdentityAuthority, RuntimeContract}

  @producer "Tiannara.Phase4.RealExecution"

  defmodule FakeBackend do
    @behaviour Tiannara.SelfImprovement.Sandbox.Backend

    @impl true
    def prepare("fail", _opts), do: {:error, :boom}
    def prepare(_baseline, _opts), do: {:ok, %{baseline: :ok}}

    @impl true
    def apply_patch(env, _patch), do: {:ok, env}

    @impl true
    def build(env, _spec), do: {:ok, env}

    @impl true
    def run_tests(_env, _spec), do: {:ok, %{all_passed: true, details: %{}}}

    @impl true
    def run_benchmark(_env, _spec), do: {:ok, %{metric: 1.0}}

    @impl true
    def teardown(_env), do: :ok
  end

  setup do
    tmp =
      Path.join([
        System.tmp_dir!(),
        "fp_root_s3_#{System.system_time(:microsecond)}_#{System.unique_integer([:positive])}"
      ])

    File.rm_rf!(tmp)
    File.mkdir_p!(tmp)

    ledger = Path.join(tmp, "identity_ledger.jsonl")
    executions = Path.join(tmp, "executions.jsonl")

    Application.put_env(:tiannara, :real_execution_enabled, true)
    Application.put_env(:tiannara, :real_execution_ledger_path, executions)
    Application.put_env(:forward_provenance, :identity_authority_ledger_path, ledger)
    IdentityAuthority.reset(ledger)

    on_exit(fn ->
      Application.delete_env(:tiannara, :real_execution_enabled)
      Application.delete_env(:tiannara, :real_execution_ledger_path)
      Application.delete_env(:forward_provenance, :identity_authority_ledger_path)
      File.rm_rf!(tmp)
    end)

    %{ledger: ledger, executions: executions}
  end

  defp minted_grant do
    {:ok, auth} = Authorization.prepare(%{explanation_id: "mc003-m-explanation"})
    {:ok, pending} = Authorization.request(auth)
    {:ok, granted} = Authorization.human_grant(pending, "c14_ac")
    granted
  end

  defp success_spec do
    %{
      id: "exp-instrumented",
      grant: minted_grant(),
      substrate: %{
        backend: FakeBackend,
        baseline: "ok",
        patch: %CodePatch{id: "p-instrumented"},
        specs: %{
          build: %{},
          tests: %TestSpec{command: "true", args: []},
          benchmark: %BenchmarkSpec{
            command: "true",
            args: [],
            metric: 1.0,
            direction: :lower_better,
            parse: &String.to_float/1
          }
        }
      }
    }
  end

  defp run_spec, do: success_spec()

  defp run_spec(baseline) when is_binary(baseline) do
    put_in(success_spec(), [:substrate, :baseline], baseline)
  end

  defp ledger_lines(path) do
    if File.exists?(path) do
      path
      |> File.stream!([], :line)
      |> Enum.map(fn line -> Jason.decode!(String.trim(line)) end)
    else
      []
    end
  end

  defp started(id, producer),
    do: %{"event_type" => "started", "execution_id" => id, "producer" => producer}

  defp completed(id, producer),
    do: %{"event_type" => "completed", "execution_id" => id, "producer" => producer}

  test "a successful real execution is authority-minted before the sandbox and ledgered once", ctx do
    assert {:ok, result} = RealExecution.execute(run_spec())

    producer = @producer

    assert {:ok,
            %{"producer" => ^producer, "id_format" => "forward_exec_v1", "source" => "mint"}} =
             IdentityAuthority.resolve(result.execution_id)

    # science-facing shape is unchanged
    assert result.provenance.execution_id == result.execution_id
    assert result.verification.verdict == :pass
    assert result.verification.harness == :real_sandbox

    # the experiment ledger carries exactly one canonical line for this run
    assert [%{"execution_id" => id, "type" => "real_execution"}] = ledger_lines(ctx.executions)
    assert id == result.execution_id
  end

  test "two executions always mint distinct canonical ids" do
    assert {:ok, r1} = RealExecution.execute(run_spec())
    assert {:ok, r2} = RealExecution.execute(run_spec())
    assert r1.execution_id != r2.execution_id

    producer = @producer
    assert {:ok, %{"producer" => ^producer}} = IdentityAuthority.resolve(r1.execution_id)
    assert {:ok, %{"producer" => ^producer}} = IdentityAuthority.resolve(r2.execution_id)
  end

  test "a failed sandbox preserves the error shape, still mints a canonical attribution, and records no fake experiment outcome", ctx do
    assert {:error, :boom} = RealExecution.execute(run_spec("fail"))

    producer = @producer

    assert [%{"producer" => ^producer, "id_format" => "forward_exec_v1", "source" => "mint"}] =
             IdentityAuthority.export()

    # no experiment outcome was fabricated for the failed run
    assert ledger_lines(ctx.executions) == []
  end

  test "K, L and terminal-state uniqueness hold at the boundary for the real module's minted id" do
    assert {:ok, result} = RealExecution.execute(run_spec())
    id = result.execution_id
    producer = @producer
    imposter = "Tiannara.OPC.Runtime.ExecutionRuntime"

    # the minted id is bound exactly to the Phase-4 producer
    assert {:ok, %{"producer" => ^producer}} = RuntimeContract.bind(id, producer)
    assert {:error, :substitution, _} = RuntimeContract.bind(id, imposter)

    # one open -> one terminal; a second terminal is a closed_attempt
    lc = RuntimeContract.start_lifecycle()
    assert {:ok, _s, lc} = RuntimeContract.accept(started(id, producer), lc)
    assert {:ok, _c, lc} = RuntimeContract.accept(completed(id, producer), lc)
    assert {:error, :closed_attempt, _} = RuntimeContract.accept(completed(id, producer), lc)

    # the imposter cannot open or close this id
    assert {:error, :substitution, _} = RuntimeContract.accept(started(id, imposter), lc)
    assert {:error, :substitution, _} = RuntimeContract.accept(completed(id, imposter), lc)
  end
end