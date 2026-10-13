defmodule Tiannara.Phase4.ExecutionGovernanceTest do
  use ExUnit.Case, async: false

  # Step-12 §8 rows "S03 real exec" / "S04 pilot": the shared admission chain
  # (ExecutionGovernance) plus both sink call orders. Every refusal is asserted
  # by its named atom; every success asserts the M3 binding, M4 single-use
  # consumption, M6 dedup claim and M8 audit edge.

  alias Tiannara.Phase4.{ExecutionGovernance, RealExecution, PhysicsPilotExecution}
  alias Tiannara.Council.AuditLog
  alias Tiannara.Omega.HumanDelivery.{Authorization, AuthenticatedHumanIdentity}
  alias Tiannara.Omega.MintRegistry
  alias Tiannara.SelfImprovement.Sandbox.{BenchmarkSpec, CodePatch, TestSpec}

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
        "eg_s12_#{System.system_time(:microsecond)}_#{System.unique_integer([:positive])}"
      ])

    File.mkdir_p!(tmp)
    Application.put_env(:tiannara, :real_execution_enabled, true)
    Application.put_env(:tiannara, :real_execution_ledger_path, Path.join(tmp, "executions.jsonl"))

    on_exit(fn ->
      Application.delete_env(:tiannara, :real_execution_enabled)
      Application.delete_env(:tiannara, :real_execution_ledger_path)
      File.rm_rf(tmp)
    end)

    :ok
  end

  defp unique, do: System.unique_integer([:positive])

  defp grant(ttl \\ 3600, mint? \\ true) do
    {:ok, auth} = Authorization.prepare(%{explanation_id: "eg-s12-#{unique()}"})
    {:ok, pending} = Authorization.request(auth)
    {:ok, identity} = AuthenticatedHumanIdentity.authenticate(:human_1, "credential", :password)
    {:ok, granted} = Authorization.human_grant(pending, identity, ttl: ttl)
    if mint?, do: :ok = Authorization.record_mint(grant_id(granted))
    granted
  end

  defp grant_id(grant), do: grant.authorization_id

  defp denied_grant do
    {:ok, auth} = Authorization.prepare(%{explanation_id: "eg-s12-denied-#{unique()}"})
    {:ok, pending} = Authorization.request(auth)
    {:ok, denied} = Authorization.human_deny(pending, "not ready")
    denied
  end

  defp s03_spec(opts \\ []) do
    id = "exp-eg-#{unique()}"
    baseline = Keyword.get(opts, :baseline, "ok")

    %{
      id: id,
      grant: grant(),
      substrate: %{
        backend: FakeBackend,
        baseline: baseline,
        patch: %CodePatch{id: "patch-#{id}"},
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

  defp audit_entry(action) do
    Enum.find(AuditLog.recent(300), &(&1.action == action))
  end

  # ------------------------------------------------------------- S03 gates --

  test "S03: an authorized real execution binds, consumes and audits, and returns measured evidence" do
    spec = s03_spec()

    assert {:ok, result} = RealExecution.execute(spec)
    assert result.verification.verdict == :pass
    assert result.verification.harness == :real_sandbox
    assert result.provenance.kind == :real_execution
    assert MintRegistry.status(grant_id(spec.grant)) == :consumed

    entry = audit_entry(:real_execution_committed)
    assert entry
    assert is_binary(entry.payload.effect_id)
    assert String.starts_with?(entry.payload.effect_id, "effect-")
    assert entry.payload.execution_recorded == true
    assert entry.payload.execution_id == result.execution_id
  end

  test "S03: one-shot consumption refuses the same grant and sink-local dedup refuses a fresh grant on the same effect" do
    spec = s03_spec()
    assert {:ok, first} = RealExecution.execute(spec)

    # M4: the consumed grant may never replay.
    assert {:error, :already_consumed} = RealExecution.execute(spec)

    # M6: a different grant targeting the identical canonical effect is refused.
    assert {:error, :effect_already_executed} = RealExecution.execute(%{spec | grant: grant()})

    assert {:ok, first}
  end

  test "S03: a failed sandbox releases the effect claim while the grant stays burned" do
    spec = s03_spec(baseline: "fail")

    assert {:error, :boom} = RealExecution.execute(spec)
    assert MintRegistry.status(grant_id(spec.grant)) == :consumed

    # The effect never happened, so a fresh grant is ADMITTED again: it passes
    # begin (claim was released, not :effect_already_executed), consumes, and
    # then fails again at the failing sandbox.
    retry_grant = grant()
    assert {:error, :boom} = RealExecution.execute(%{spec | grant: retry_grant})
    assert MintRegistry.status(grant_id(retry_grant)) == :consumed
  end

  test "S03: audit failure after the effect is recorded is fail-closed and keeps the claim" do
    spec = s03_spec()
    pid = Process.whereis(AuditLog)
    Process.unregister(AuditLog)

    result =
      try do
        RealExecution.execute(spec)
      after
        Process.register(pid, AuditLog)
      end

    assert {:error, {:audit_not_recorded, _reason, detail}} = result
    assert detail.execution_recorded == true
    assert is_binary(detail.effect_id)

    # The execution did occur: the claim survives the audit failure.
    assert {:error, :effect_already_executed} = RealExecution.execute(%{spec | grant: grant()})
  end

  test "S03: refusals carry their named atoms before any execution" do
    # disabled wins first
    Application.put_env(:tiannara, :real_execution_enabled, false)
    assert {:error, :real_execution_not_enabled} = RealExecution.execute(s03_spec())
    Application.put_env(:tiannara, :real_execution_enabled, true)

    assert {:error, :authorization_grant_required} = RealExecution.execute(%{id: "e-eg"})

    denied = denied_grant()
    assert {:error, :authorization_grant_denied} = RealExecution.execute(%{s03_spec() | grant: denied})

    expired = grant(-1)
    assert {:error, :grant_expired} = RealExecution.execute(%{s03_spec() | grant: expired})

    unminted = grant(3600, false)
    assert {:error, :authorization_not_registered} =
             RealExecution.execute(%{s03_spec() | grant: unminted})
  end

  test "S03: ExecutionGovernance refuses a non-grant struct outright" do
    assert {:error, :authorization_grant_required} = ExecutionGovernance.begin(:nope, %{})
    assert {:error, :authorization_grant_denied} = ExecutionGovernance.begin(denied_grant(), %{})
  end

  # ------------------------------------------------------------- S04 gates --

  test "S04: one pilot run executes, consumes and audits; replay and fresh-grant rerun are refused" do
    g1 = grant()

    assert {:ok, result} = PhysicsPilotExecution.execute(%{grant: g1})
    assert is_binary(result.execution_id)
    assert String.starts_with?(result.execution_id, "pilot_")
    assert result.provenance.kind == :real_execution
    assert result.verification.harness == :real_simulation
    assert is_binary(result.effect_id)

    assert MintRegistry.status(grant_id(g1)) == :consumed

    # M4 replay refusal
    assert {:error, :already_consumed} = PhysicsPilotExecution.execute(%{grant: g1})

    # M6: identical canonical pilot descriptor with a fresh grant
    assert {:error, :effect_already_executed} = PhysicsPilotExecution.execute(%{grant: grant()})

    entry = audit_entry(:physics_pilot_executed)
    assert entry
    assert entry.payload.effect_id == result.effect_id
    assert entry.payload.execution_recorded == true
  end

  test "S04: the sink guard preserves the denied and expired atoms before admission" do
    assert {:error, :authorization_grant_required} = PhysicsPilotExecution.execute(%{})

    assert {:error, :authorization_grant_denied} =
             PhysicsPilotExecution.execute(%{grant: denied_grant()})

    assert {:error, :grant_expired} = PhysicsPilotExecution.execute(%{grant: grant(-1)})
  end

  test "S04: an unminted grant is refused by the registry gate" do
    unminted = grant(3600, false)

    assert {:error, :authorization_not_registered} =
             PhysicsPilotExecution.execute(%{grant: unminted})
  end
end
