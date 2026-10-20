defmodule TiannaraRuntime.ApplicationTest do
  use ExUnit.Case

  describe "Application.start/2" do
    test "application can be started with ensure_all_started" do
      # ensure_all_started/1 returns {:ok, apps} with only the apps it had
      # to start — an already-running :tiannara_runtime yields {:ok, []}.
      # The intent is: after the call, the app must be running.
      case Application.ensure_all_started(:tiannara_runtime) do
        {:ok, _apps} ->
          assert Enum.any?(Application.started_applications(), fn {app, _desc, _vsn} ->
                   app == :tiannara_runtime
                 end)

        {:error, {:already_started, _}} ->
          :ok
      end
    end

    test "application returns {:ok, pid} from start callback" do
      case TiannaraRuntime.Application.start(:normal, []) do
        {:ok, pid} ->
          assert is_pid(pid)

        {:error, {:already_started, pid}} ->
          assert is_pid(pid)
      end
    end
  end
end
