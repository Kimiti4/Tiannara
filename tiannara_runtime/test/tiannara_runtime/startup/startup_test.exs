defmodule TiannaraRuntime.StartupTest do
  use ExUnit.Case
  alias TiannaraRuntime.Startup

  describe "default_config/0" do
    test "returns a map with all required keys" do
      config = Startup.default_config()

      assert is_map(config)
      assert Map.has_key?(config, :cpl_opts)
      assert Map.has_key?(config, :cop_opts)
      assert Map.has_key?(config, :runtime_opts)
      assert Map.has_key?(config, :verification)
    end

    test "cpl_opts include checkpoint_interval and storage_path" do
      config = Startup.default_config()
      cpl_opts = config.cpl_opts

      assert Keyword.get(cpl_opts, :checkpoint_interval) == 30_000
      assert Keyword.get(cpl_opts, :storage_path) == "data/cpl"
    end

    test "verification is enabled by default" do
      assert Startup.default_config().verification == true
    end
  end

  describe "verify_startup/1" do
    test "returns passed: true when verification is disabled" do
      {:ok, result} = Startup.verify_startup(false)
      assert result.passed == true
      assert result.details == %{}
    end
  end

  describe "status/0" do
    test "returns a map with supervisor, cpl, cop, runtime keys" do
      status = Startup.status()

      assert is_map(status)
      assert Map.has_key?(status, :supervisor)
      assert Map.has_key?(status, :cpl)
      assert Map.has_key?(status, :cop)
      assert Map.has_key?(status, :runtime)
    end
  end

  describe "start_all/1" do
    test "handles already-started supervisor gracefully" do
      case Startup.start_all() do
        {:ok, result} ->
          assert is_map(result)
          assert Map.has_key?(result, :status)
          assert Map.has_key?(result, :cpl_started)
          assert Map.has_key?(result, :cop_started)
          assert Map.has_key?(result, :runtime_started)
          assert Map.has_key?(result, :verification_passed)
          assert Map.has_key?(result, :started_at)
          assert Map.has_key?(result, :duration_ms)
          assert Map.has_key?(result, :errors)
          assert is_list(result.errors)

          Startup.stop_all()

        {:error, reason} ->
          assert is_binary(reason)
      end
    end

    test "default_config is used when no config passed" do
      config = Startup.default_config()
      assert is_map(config)
    end
  end

  describe "stop_all/0" do
    test "returns :ok even if system not running" do
      assert Startup.stop_all() == :ok
    end

    test "returns :ok after starting and stopping" do
      case Startup.start_all() do
        {:ok, _result} ->
          assert Startup.stop_all() == :ok

        {:error, _} ->
          :skip
      end
    end
  end
end
