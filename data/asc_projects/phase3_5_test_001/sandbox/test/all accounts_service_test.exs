defmodule All accountsServiceTest do
  use ExUnit.Case
  doctest All accountsService

  alias All accountsService

  describe "all accountsService" do
      test "list_all accounts returns not_implemented" do
    # TODO: Replace with actual test based on TestContract
    assert {:error, :not_implemented} = All accountsService.list_all accounts(%{})
  end

  end
end
