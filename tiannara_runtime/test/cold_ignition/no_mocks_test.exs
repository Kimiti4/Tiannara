defmodule ColdIgnition.NoMocksTest do
  @moduledoc """
  PHASE 2: COLD IGNITION - STEP 1
  Verify that no mock layers are active at startup.
  All state must be runtime-generated, not seeded or precomputed.
  """
  use ExUnit.Case

  setup do
    {:ok, _started} = Application.ensure_all_started(:tiannara_runtime)
    :ok
  end

  # CI-A inventory finding (Elixir CI run 39363009648 + local fresh-build
  # repro): the original check filtered :code.all_loaded() for module
  # names containing "Mock", which conflates LOADED with ACTIVE. On any
  # fresh checkout (CI) the compiler loads every compiled module into
  # the test VM before ExUnit starts, so the check failed deterministically
  # on a cold _build and passed only on a warm local _build — it never
  # tested the actual finding. The finding itself is preserved below:
  # no mock observatory PROCESS may be running and no mock
  # certification report may exist, i.e. no mock layers are ACTIVE.
  test "no mock supervisors active" do
    running_mocks =
      Enum.filter(mock_observatory_modules(), fn mod ->
        Process.whereis(mod) != nil
      end)

    assert running_mocks == [],
           "Found active mock observatory processes: #{inspect(running_mocks)}"

    case Process.whereis(Tiannara.Sentinel.Validation.ValidationState) do
      nil ->
        :ok

      _pid ->
        report = Tiannara.Sentinel.Validation.ValidationState.get_report()

        assert report == nil,
               "Mock certification report is active: #{inspect(report)}"
    end
  end

  test "RootSupervisor has exactly 5 children" do
    {:ok, supervisor} = start_root_supervisor()
    children = Supervisor.which_children(supervisor)

    assert Enum.count(children) == 5,
           "RootSupervisor should have 5 children, found #{Enum.count(children)}"
  end

  test "authority layers are direct children of root" do
    {:ok, supervisor} = start_root_supervisor()
    children = Supervisor.which_children(supervisor)

    layer_names = Enum.map(children, fn {id, _pid, _type, _mods} -> id end)

    expected_layers = [
      :infrastructure,
      :execution,
      :ecology,
      :constraint,
      :meta
    ]

    Enum.each(expected_layers, fn layer ->
      assert Enum.member?(layer_names, layer),
             "Missing authority layer: #{layer}"
    end)
  end

  test "no nested supervision chains" do
    # Verify that layers don't supervise each other directly
    {:ok, supervisor} = start_root_supervisor()
    children = Supervisor.which_children(supervisor)

    Enum.each(children, fn {_id, pid, _type, _mods} ->
      # Each layer supervisor should have children, but those children
      # should not be other authority supervisors
      case Supervisor.which_children(pid) do
        children when is_list(children) ->
          illegal_layers = Enum.filter(children, fn {child_id, _cpid, _type, _cmods} ->
            Enum.member?([:infrastructure, :execution, :ecology, :constraint, :meta], child_id)
          end)

          assert illegal_layers == [],
                 "Found nested layer supervision: #{inspect(illegal_layers)}"

        _ ->
          # Not a supervisor, OK
          :ok
      end
    end)
  end

  # --- Helpers ---

  defp mock_observatory_modules do
    [
      Tiannara.Sentinel.Validation.MockObservatories.AdaptiveDriftObservatory,
      Tiannara.Sentinel.Validation.MockObservatories.NoisyObservatory,
      Tiannara.Sentinel.Validation.MockObservatories.UnderconfidentObservatory,
      Tiannara.Sentinel.Validation.MockObservatories.RandomObservatory,
      Tiannara.Sentinel.Validation.MockObservatories.MonocultureObservatory,
      Tiannara.Sentinel.Validation.MockObservatories.OverconfidentObservatory,
      Tiannara.Sentinel.Validation.MockObservatories.ContrarianObservatory,
      Tiannara.Sentinel.Validation.MockObservatories.PerfectObservatory
    ]
  end

  defp start_root_supervisor do
    try do
      case Process.whereis(TiannaraRuntime.RootSupervisor) do
        pid when is_pid(pid) -> {:ok, pid}
        nil -> {:error, :not_started}
      end
    rescue
      _ -> {:error, :error}
    end
  end
end
