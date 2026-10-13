defmodule Tiannara.Omega.Step13R2MintAuthenticationTest do
  use ExUnit.Case, async: false

  alias Tiannara.Council.{Authorization, MachineAuthorization}
  alias Tiannara.Omega.HumanDelivery
  alias Tiannara.Omega.MintRegistry

  setup do
    unless Process.whereis(MintRegistry), do: start_supervised!(MintRegistry)
    :ok
  end

  defp fresh_id(tag) do
    :"step13-r2-#{tag}-#{System.unique_integer([:positive])}"
  end

  describe "R-2 registry minter authentication" do
    test "a direct call from a non-allowlisted process is refused fail-closed" do
      id = fresh_id("forge")

      assert {:error, :minter_not_authorized} = MintRegistry.record_mint(id)
      assert MintRegistry.status(id) == :not_registered
    end

    test "the refusal happens before any registry write" do
      id_a = fresh_id("forge-a")
      id_b = fresh_id("forge-b")

      assert {:error, :minter_not_authorized} = MintRegistry.record_mint(id_a, [])
      assert {:error, :minter_not_authorized} = MintRegistry.record_mint(id_b, council_decision_ref: String.duplicate("0", 64))

      assert MintRegistry.status(id_a) == :not_registered
      assert MintRegistry.status(id_b) == :not_registered
    end

    test "the human-path wrapper (allowlisted stack origin) registers successfully" do
      id = fresh_id("human")

      assert :ok = HumanDelivery.Authorization.record_mint(id)
      assert MintRegistry.status(id) == :granted
      assert MintRegistry.decision_ref(id) == nil

      assert {:error, {:already_registered, ^id}} = HumanDelivery.Authorization.record_mint(id)
    end

    test "machine mints through MachineAuthorization remain permitted" do
      decision = Authorization.approved(explanation: "step-13 r2 machine path")

      assert {:ok, auth} =
               MachineAuthorization.mint(decision, decision_type: :world_mutation, ttl: 60)

      assert MintRegistry.status(auth.authorization_id) == :granted
      assert MintRegistry.decision_ref(auth.authorization_id) == auth.council_decision_ref
    end
  end
end
