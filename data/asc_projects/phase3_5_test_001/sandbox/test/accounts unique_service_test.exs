defmodule Accounts uniqueServiceTest do
  use ExUnit.Case
  doctest Accounts uniqueService

  alias Accounts uniqueService

  describe "accounts uniqueService" do
      test "create_accounts unique returns not_implemented" do
    # TODO: Replace with actual test based on TestContract
    assert {:error, :not_implemented} = Accounts uniqueService.create_accounts unique(%{})
  end

  end
end
