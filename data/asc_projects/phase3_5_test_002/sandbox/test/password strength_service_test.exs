defmodule Password strengthServiceTest do
  use ExUnit.Case
  doctest Password strengthService

  alias Password strengthService

  describe "password strengthService" do
      test "validate_password strength returns not_implemented" do
    # TODO: Replace with actual test based on TestContract
    assert {:error, :not_implemented} = Password strengthService.validate_password strength(%{})
  end

  end
end
