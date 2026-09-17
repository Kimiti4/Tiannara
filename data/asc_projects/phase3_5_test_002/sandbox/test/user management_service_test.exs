defmodule User managementServiceTest do
  use ExUnit.Case
  doctest User managementService

  alias User managementService

  describe "user managementService" do
      test "create_user management returns not_implemented" do
    # TODO: Replace with actual test based on TestContract
    assert {:error, :not_implemented} = User managementService.create_user management(%{})
  end

  end
end
