defmodule Tiannara.Phase4.RealExecutionTest do
  use ExUnit.Case, async: false

  alias Tiannara.Phase4.{RealExecution, ExperimentOrchestrator}
  alias Tiannara.Omega.HumanDelivery.Authorization

  setup do
    Application.delete_env(:tiannara, :real_execution_enabled)

    on_exit(fn ->
      Application.delete_env(:tiannara, :real_execution_enabled)
    end)

    :ok
  end

  defp minted_grant do
    {:ok, auth} = Authorization.prepare(%{explanation_id: "mc003-m-explanation"})
    {:ok, pending} = Authorization.request(auth)
    {:ok, granted} = Authorization.human_grant(pending, "c14_ac")
    granted
  end

  describe "gate (MC-003-M M2)" do
    test "execute/1 is refused when real execution is disabled" do
      Application.put_env(:tiannara, :real_execution_enabled, false)
      assert {:error, :real_execution_not_enabled} = RealExecution.execute(%{id: "e1", grant: minted_grant()})
    end

    test "submit_experiment/1 is refused when real execution is disabled" do
      Application.put_env(:tiannara, :real_execution_enabled, false)
      assert {:error, :real_execution_not_enabled} = ExperimentOrchestrator.submit_experiment(%{id: "e1"})
    end

    test "execute/1 requires an authorization grant" do
      Application.put_env(:tiannara, :real_execution_enabled, true)
      assert {:error, :authorization_grant_required} = RealExecution.execute(%{id: "e1"})
    end

    test "execute/1 requires a real substrate even when granted" do
      Application.put_env(:tiannara, :real_execution_enabled, true)
      result = RealExecution.execute(%{id: "e1", grant: minted_grant()})
      assert {:error, reason} = result
      assert reason in [:no_real_execution_substrate_configured, :authorization_grant_required]
    end

    test "enabled?/0 reflects the feature flag" do
      Application.put_env(:tiannara, :real_execution_enabled, true)
      assert RealExecution.enabled?() == true
      Application.put_env(:tiannara, :real_execution_enabled, false)
      assert RealExecution.enabled?() == false
    end
  end
end