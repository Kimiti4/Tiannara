defmodule Low-stock itemsServiceTest do
  use ExUnit.Case
  doctest Low-stock itemsService

  alias Low-stock itemsService

  describe "low-stock itemsService" do
      test "list_low-stock items returns not_implemented" do
    # TODO: Replace with actual test based on TestContract
    assert {:error, :not_implemented} = Low-stock itemsService.list_low-stock items(%{})
  end

  end
end
