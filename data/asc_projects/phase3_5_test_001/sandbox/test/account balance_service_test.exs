defmodule Account balanceServiceTest do
  use ExUnit.Case
  doctest Account balanceService

  alias Account balanceService

  describe "account balanceService" do
      test "update_account balance returns not_implemented" do
    # TODO: Replace with actual test based on TestContract
    assert {:error, :not_implemented} = Account balanceService.update_account balance(%{})
  end

  end
end
