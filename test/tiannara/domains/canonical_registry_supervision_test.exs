defmodule Tiannara.Domains.CanonicalRegistrySupervisionTest do
  @moduledoc """
  AC-001-B: Supervision tree integration tests.

  Verifies:
  - Registry starts with application
  - Registry is supervised
  - Registry restarts on crash
  - Registry remains queryable after restart
  """

  use ExUnit.Case, async: false

  alias Tiannara.Domains.CanonicalRegistry

  describe "supervision" do
    test "registry is started by application" do
      pid = Process.whereis(CanonicalRegistry)
      assert pid != nil, "CanonicalRegistry should be started by application"
      assert Process.alive?(pid), "CanonicalRegistry process should be alive"
    end

    test "registry restarts on crash" do
      pid = Process.whereis(CanonicalRegistry)
      assert pid != nil

      ref = Process.monitor(pid)

      Process.exit(pid, :kill)

      assert_receive {:DOWN, ^ref, :process, ^pid, :killed}, 1000

      Process.sleep(100)

      new_pid = Process.whereis(CanonicalRegistry)
      assert new_pid != nil, "CanonicalRegistry should be restarted by supervisor"
      assert new_pid != pid, "Should be a new process"
      assert Process.alive?(new_pid), "New process should be alive"
    end

    test "registry remains queryable after restart" do
      pid = Process.whereis(CanonicalRegistry)
      Process.exit(pid, :kill)
      Process.sleep(200)

      assert {:ok, record} = CanonicalRegistry.get(:physics)
      assert record.id == :physics

      domains = CanonicalRegistry.all()
      assert length(domains) == 20
    end

    test "registry state is reinitialized after restart" do
      pid = Process.whereis(CanonicalRegistry)
      Process.exit(pid, :kill)
      Process.sleep(200)

      {:ok, restarted_record} = CanonicalRegistry.get(:physics)
      assert restarted_record.id == :physics
      assert restarted_record.lifecycle == :active
    end
  end

  describe "application startup" do
    test "application starts without errors" do
      assert {:ok, _} = CanonicalRegistry.get(:engineering)
    end

    test "ontology version is accessible after boot" do
      version = CanonicalRegistry.ontology_version()
      assert version == "1.0.0"
    end
  end
end
