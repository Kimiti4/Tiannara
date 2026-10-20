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

  test "no mock supervisors active" do
    active_mods = :code.all_loaded()

    mocks =
      Enum.filter(active_mods, fn {mod, _beam} ->
        mod != ColdIgnition.NoMocksTest and
          (mod |> Atom.to_string() |> String.contains?("Mock"))
      end)

    assert mocks == [],
           "Found active mock modules: #{Enum.map(mocks, fn {mod, _beam} -> Atom.to_string(mod) end) |> Enum.join(", ")}"
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
