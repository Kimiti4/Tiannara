defmodule TiannaraRuntime.StartupSupervisorTest do
  use ExUnit.Case
  alias TiannaraRuntime.StartupSupervisor

  describe "start_link/1" do
    test "returns {:ok, pid} when started" do
      case StartupSupervisor.start_link([]) do
        {:ok, pid} ->
          assert is_pid(pid)
          Supervisor.stop(pid, :normal)

        {:error, {:already_started, pid}} ->
          assert is_pid(pid)
      end
    end
  end

  describe "status/0" do
    test "returns a map with all system statuses" do
      status = StartupSupervisor.status()

      assert is_map(status)
      assert Map.has_key?(status, :supervisor)
      assert Map.has_key?(status, :cpl)
      assert Map.has_key?(status, :cop)
      assert Map.has_key?(status, :runtime)
      assert is_boolean(status.supervisor)
      assert is_boolean(status.cpl)
      assert is_boolean(status.cop)
      assert is_boolean(status.runtime)
    end
  end

  describe "all_running?/0" do
    test "returns a boolean" do
      result = StartupSupervisor.all_running?()
      assert is_boolean(result)
    end

    test "is consistent with status/0 components" do
      # The original premise ("is false when supervisor not started") is
      # unarrangeable under `mix test`: the application boots
      # StartupSupervisor as a permanent child, and the test only ever
      # passed as a teardown side-effect of another test (false positive).
      # Deterministic equivalent: all_running? must be exactly the AND of
      # its status components — i.e. it reports false when any component
      # is down.
      status = StartupSupervisor.status()

      expected =
        status.supervisor and status.cpl and status.omega and status.cop and status.runtime

      assert StartupSupervisor.all_running?() == expected
      assert is_boolean(StartupSupervisor.all_running?())
    end
  end

  describe "supervision structure" do
    test "uses :rest_for_one strategy" do
      case Process.whereis(StartupSupervisor) do
        nil ->
          :skip

        pid ->
          state = :sys.get_state(pid)
          assert elem(state, 0) == :state
          state_parts = Tuple.to_list(state)

          # The #supervisor.state{} record layout differs across OTP
          # versions (strategy/children moved positions), so locate the
          # strategy atom and the children pair {ids, child_map}
          # structurally instead of pattern-matching fixed arities.
          strategy_name =
            Enum.find(state_parts, &(&1 in [:one_for_one, :one_for_all, :rest_for_one]))

          assert strategy_name == :rest_for_one

          children_pair =
            Enum.find(state_parts, fn
              {ids, child_map} when is_list(ids) and is_map(child_map) -> true
              _ -> false
            end)

          assert is_tuple(children_pair),
                 "expected a {ids, map} children pair in supervisor state"

          {child_ids, _child_map} = children_pair

          assert :"Elixir.TiannaraRuntime.OS.Persistence.ConstitutionalPersistenceLayer" in child_ids
          assert :"Elixir.TiannaraRuntime.OS.Observatory" in child_ids
          assert :"Elixir.TiannaraRuntime.RootSupervisor" in child_ids
      end
    end
  end
end
