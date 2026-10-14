defmodule Tiannara.Phase4.RealExecutionTest do
  use ExUnit.Case, async: false

  alias Tiannara.Phase4.{RealExecution, ExperimentOrchestrator}
  alias Tiannara.Omega.HumanDelivery.{Authorization, AuthenticatedHumanIdentity}

  setup do
    Application.delete_env(:tiannara, :real_execution_enabled)

    # Isolate the execution ledger — never append test artifacts to the
    # tracked canonical file under priv/.
    Application.put_env(
      :tiannara,
      :real_execution_ledger_path,
      Path.join(System.tmp_dir!(), "real_exec_#{System.unique_integer([:positive])}.jsonl")
    )

    on_exit(fn ->
      Application.delete_env(:tiannara, :real_execution_enabled)
      Application.delete_env(:tiannara, :real_execution_ledger_path)
    end)

    :ok
  end

  defp minted_grant do
    {:ok, identity} = AuthenticatedHumanIdentity.authenticate("c14_ac", "credential", :password)

    {:ok, auth} =
      Authorization.prepare(%{
        explanation_id: "mc003-m-explanation-#{System.unique_integer([:positive])}"
      })

    {:ok, pending} = Authorization.request(auth)
    {:ok, granted} = Authorization.human_grant(pending, identity)
    :ok = Authorization.record_mint(granted.authorization_id)
    granted
  end

  describe "gate (MC-003-M M2)" do
    test "execute/1 is refused when real execution is disabled" do
      Application.put_env(:tiannara, :real_execution_enabled, false)

      assert {:error, :real_execution_not_enabled} =
               RealExecution.execute(%{id: "e1", grant: minted_grant()})
    end

    test "submit_experiment/1 is refused when real execution is disabled" do
      Application.put_env(:tiannara, :real_execution_enabled, false)

      assert {:error, :real_execution_not_enabled} =
               ExperimentOrchestrator.submit_experiment(%{id: "e1"})
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
