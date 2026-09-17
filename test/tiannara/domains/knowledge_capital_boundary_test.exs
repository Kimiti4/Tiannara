defmodule Tiannara.Domains.KnowledgeCapitalBoundaryTest do
  use ExUnit.Case, async: true

  alias Tiannara.Domains.KnowledgeCapitalBoundary

  describe "get/1" do
    test "returns nil for any domain" do
      assert KnowledgeCapitalBoundary.get(:engineering) == nil
      assert KnowledgeCapitalBoundary.get(:computation) == nil
      assert KnowledgeCapitalBoundary.get(:physics) == nil
      assert KnowledgeCapitalBoundary.get(:invalid_domain) == nil
    end
  end

  describe "available?/0" do
    test "returns false" do
      assert KnowledgeCapitalBoundary.available?() == false
    end
  end

  describe "status/0" do
    test "returns :unavailable" do
      assert KnowledgeCapitalBoundary.status() == :unavailable
    end
  end
end
