defmodule Tiannara.Physics.MC004PPilotExecutionTest do
  use ExUnit.Case, async: false

  alias Tiannara.Phase4.{PhysicsPilotExecution, RealExecution}
  alias Tiannara.Domains.Physics
  alias Tiannara.Foundations.Mathematics.Calculus
  alias Tiannara.Omega.HumanDelivery.Authorization

  @executions_log "priv/tiannara/real_execution/executions.jsonl"

  setup do
    Application.delete_env(:tiannara, :real_execution_enabled)

    on_exit(fn ->
      Application.delete_env(:tiannara, :real_execution_enabled)
    end)

    :ok
  end

  defp minted_grant do
    {:ok, auth} = Authorization.prepare(%{explanation_id: "mc004-p-pilot"})
    {:ok, pending} = Authorization.request(auth)
    {:ok, granted} = Authorization.human_grant(pending, "c14_ac")
    granted
  end

  describe "MC-004-P pilot execution" do
    test "produces real execution evidence via PhysicsPilotExecution" do
      Application.put_env(:tiannara, :real_execution_enabled, true)

      assert {:ok, result} = PhysicsPilotExecution.execute(%{grant: minted_grant()})
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

      pilot = Physics.pilot_experiment()
      spec = %{grant: minted_grant(), pilot: pilot}

      assert {:ok, result} = Physics.execute_experiment(spec)
      assert result.provenance.kind == :real_execution
      assert result.verification.harness == :real_simulation
    end

    test "records execution to JSONL ledger" do
      Application.put_env(:tiannara, :real_execution_enabled, true)

      before_content =
        if File.exists?(@executions_log),
          do: File.read!(@executions_log),
          else: ""

      assert {:ok, _result} = PhysicsPilotExecution.execute(%{grant: minted_grant()})

      after_content = File.read!(@executions_log)
      new_entries = String.replace(after_content, before_content, "")

      assert new_entries =~ "\"subsystem\":\"physics_pilot\""
      assert new_entries =~ "\"type\":\"real_execution\""
      assert new_entries =~ "\"harness\":\"real_simulation\""
    end

    test "refuses when real execution is disabled" do
      Application.put_env(:tiannara, :real_execution_enabled, false)

      assert {:error, :real_execution_not_enabled} =
               Physics.execute_experiment(%{hypothesis: %{subject: :test}, context: %{}})
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
