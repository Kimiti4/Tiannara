defmodule New usersServiceTest do
  use ExUnit.Case
  doctest New usersService

  alias New usersService

  describe "new usersService" do
      test "register_new users returns not_implemented" do
    # TODO: Replace with actual test based on TestContract
    assert {:error, :not_implemented} = New usersService.register_new users(%{})
  end

  end
end
