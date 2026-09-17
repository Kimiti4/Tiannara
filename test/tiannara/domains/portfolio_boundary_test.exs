defmodule Tiannara.Domains.PortfolioBoundaryTest do
  use ExUnit.Case, async: true

  alias Tiannara.Domains.PortfolioBoundary

  describe "get/1" do
    test "returns nil for any domain" do
      assert PortfolioBoundary.get(:engineering) == nil
      assert PortfolioBoundary.get(:computation) == nil
      assert PortfolioBoundary.get(:physics) == nil
      assert PortfolioBoundary.get(:invalid_domain) == nil
    end
  end

  describe "available?/0" do
    test "returns false" do
      assert PortfolioBoundary.available?() == false
    end
  end

  describe "status/0" do
    test "returns :unavailable" do
      assert PortfolioBoundary.status() == :unavailable
    end
  end
end
