defmodule Users byServiceTest do
  use ExUnit.Case
  doctest Users byService

  alias Users byService

  describe "users byService" do
      test "list_users by returns not_implemented" do
    # TODO: Replace with actual test based on TestContract
    assert {:error, :not_implemented} = Users byService.list_users by(%{})
  end

  end
end
