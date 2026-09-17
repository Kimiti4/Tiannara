defmodule Tiannara.ApplicationGatingTest do
  use ExUnit.Case, async: true

  alias Tiannara.Application

  describe "asc_enabled?/0" do
    test "reads the :tiannara, :asc feature flag from config" do
      assert Application.asc_enabled?() ==
               (:application.get_env(:tiannara, :asc, []) |> Keyword.get(:enabled, false))
    end
  end

  describe "asc_children/1" do
    test "returns no children when ASC is disabled" do
      assert Application.asc_children(false) == []
    end

    test "returns the ASC supervisors when enabled" do
      children = Application.asc_children(true)
      assert length(children) > 0
      assert {Tiannara.ASC.Core.Supervisor, []} in children
      assert {Tiannara.ASC.Civilization.Supervisor, []} in children
      assert {Tiannara.ASC.Reality.Supervisor, []} in children
    end
  end

  describe "loop_children/0" do
    test "loop plumbing is independent of the ASC flag" do
      loop = Application.loop_children()
      assert {Tiannara.Operations.CampaignIntegration, []} in loop
      assert {Tiannara.Operations.CampaignScheduler, []} in loop
      assert {Tiannara.Operations.Phase5FeedbackListener, []} in loop
      assert {Tiannara.Operations.CampaignTelemetry, []} in loop
    end

    test "loop plumbing never depends on an ASC module" do
      loop_modules = Application.loop_children() |> Enum.map(&elem(&1, 0))

      refute Enum.any?(loop_modules, fn m ->
               String.starts_with?(inspect(m), "Tiannara.ASC")
             end)
    end
  end
end
