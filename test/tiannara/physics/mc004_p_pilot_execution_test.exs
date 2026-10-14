defmodule Tiannara.Physics.MC004PPilotExecutionTest do
  use ExUnit.Case, async: false

  alias Tiannara.Phase4.PhysicsPilotExecution
  alias Tiannara.Domains.Physics
  alias Tiannara.Foundations.Mathematics.Calculus
  alias Tiannara.Omega.HumanDelivery.{Authorization, AuthenticatedHumanIdentity}

  setup do
    Application.delete_env(:tiannara, :real_execution_enabled)

    # Isolate the execution ledger so tests never append to the tracked
    # canonical file under priv/ (evidence integrity: test artifacts and
    # production evidence must not interleave).
    ledger =
      Path.join(
        System.tmp_dir!(),
        "mc004_p_executions_#{System.unique_integer([:positive])}.jsonl"
      )

    Application.put_env(:tiannara, :real_execution_ledger_path, ledger)

    on_exit(fn ->
      Application.delete_env(:tiannara, :real_execution_enabled)
      Application.delete_env(:tiannara, :real_execution_ledger_path)
    end)

    {:ok, ledger: ledger}
  end

  defp minted_grant do
    {:ok, identity} = AuthenticatedHumanIdentity.authenticate("c14_ac", "credential", :password)

    {:ok, auth} =
      Authorization.prepare(%{
        explanation_id: "mc004-p-pilot-#{System.unique_integer([:positive])}"
      })

    {:ok, pending} = Authorization.request(auth)
    {:ok, granted} = Authorization.human_grant(pending, identity)
    :ok = Authorization.record_mint(granted.authorization_id)
    granted
  end

  # A pilot whose context carries a unique run_id marker, so the canonical
  # effect_id (fingerprinted from hypothesis/context) is a fresh identity each
  # call — avoiding M6 single-use dedup collisions across tests. The marker is
  # merged into the valid pilot context (boundary_conditions/time_span intact).
  defp unique_pilot do
    pilot = Physics.pilot_experiment()
    put_in(pilot, [:context, :run_id], "mc004-p-#{System.unique_integer([:positive])}")
  end

  describe "MC-004-P pilot execution" do
    test "produces real execution evidence via PhysicsPilotExecution" do
      Application.put_env(:tiannara, :real_execution_enabled, true)

      assert {:ok, result} =
               PhysicsPilotExecution.execute(%{grant: minted_grant(), pilot: unique_pilot()})

      assert is_binary(result.execution_id)
      assert String.starts_with?(result.execution_id, "pilot_")
      assert result.provenance.kind == :real_execution
      assert result.verification.harness == :real_simulation
      assert result.verification.method == :rk4
      assert is_list(result.simulation.result.trajectory)
      assert length(result.simulation.result.trajectory) > 0
    end

    test "MC-004-P bridges through Physics.execute_experiment with grant" do
      Application.put_env(:tiannara, :real_execution_enabled, true)

      pilot = unique_pilot()
      spec = %{grant: minted_grant(), pilot: pilot}

      assert {:ok, result} = Physics.execute_experiment(spec)
      assert result.provenance.kind == :real_execution
      assert result.verification.harness == :real_simulation
    end

    test "records execution to JSONL ledger with provenance", %{ledger: ledger} do
      Application.put_env(:tiannara, :real_execution_enabled, true)

      assert {:ok, result} =
               PhysicsPilotExecution.execute(%{grant: minted_grant(), pilot: unique_pilot()})

      assert File.exists?(ledger)
      [entry] = ledger |> File.read!() |> String.split("\n", trim: true) |> Enum.map(&Jason.decode!/1)

      assert entry["type"] == "real_execution"
      assert entry["subsystem"] == "physics_pilot"
      assert entry["execution_id"] == result.execution_id
      assert entry["verification"]["harness"] == "real_simulation"
      assert entry["provenance"]["kind"] == "real_execution"
      assert entry["provenance"]["execution_id"] == result.execution_id
    end

    test "ledger write failure fails closed and does not release the grant claim" do
      Application.put_env(:tiannara, :real_execution_enabled, true)

      # Point the ledger at a directory so File.write! raises deterministically.
      blocked =
        Path.join(System.tmp_dir!(), "mc004_p_blocked_#{System.unique_integer([:positive])}")

      File.mkdir_p!(blocked)
      Application.put_env(:tiannara, :real_execution_ledger_path, blocked)

      spec = %{grant: minted_grant(), pilot: unique_pilot()}

      assert {:error, {:execution_ledger_write_failed, _detail}} =
               PhysicsPilotExecution.execute(spec)

      # Post-effect failure: the claim must stay consumed — a retry of the
      # same canonical effect is refused rather than silently re-executed.
      assert {:error, second_reason} = PhysicsPilotExecution.execute(spec)
      assert second_reason in [:effect_already_executed, :already_consumed]
    end

    test "refuses when real execution is disabled" do
      Application.put_env(:tiannara, :real_execution_enabled, false)

      assert {:error, :real_execution_not_enabled} =
               Physics.execute_experiment(%{hypothesis: %{subject: :test}, context: %{}})
    end

    test "direct provider refuses when real execution is disabled" do
      assert {:error, :real_execution_not_enabled} =
               PhysicsPilotExecution.execute(%{grant: minted_grant(), pilot: unique_pilot()})
    end

    test "refuses without a grant" do
      Application.put_env(:tiannara, :real_execution_enabled, true)

      assert {:error, :authorization_grant_required} =
               PhysicsPilotExecution.execute(%{})
    end

    test "refuses with a denied grant" do
      Application.put_env(:tiannara, :real_execution_enabled, true)

      {:ok, auth} = Authorization.prepare(%{explanation_id: "mc004-p-denied"})
      {:ok, pending} = Authorization.request(auth)
      {:ok, denied} = Authorization.human_deny(pending, "not ready")

      assert {:error, :authorization_grant_denied} =
               PhysicsPilotExecution.execute(%{grant: denied})
    end

    test "MC-001 pins preserved after pilot execution" do
      assert {:error, :ode_solver_unavailable} = Calculus.solve_ode(%{}, %{}, 1.0)

      assert {:error, :formal_verification_unavailable} =
               Physics.validate(%{model: %{}})
    end
  end
end
