defmodule Tiannara.RuntimeLayers.NativeBridgeTest do
  @moduledoc """
  Validation of the single, configuration-driven native accelerator boundary.

  Every per-phase `NativeBridge` delegates here. These tests pin that the
  accelerator inventory comes from configuration, that paths resolve against
  the running OTP application rather than a hardcoded atom, and that a missing
  accelerator fails closed with a typed reason instead of raising.
  """
  use ExUnit.Case, async: false

  alias TiannaraRuntime.NativeBridge

  @accelerator :rrm_native_jit

  setup do
    original = Application.get_env(:tiannara_runtime, :native_accelerators)
    on_exit(fn -> Application.put_env(:tiannara_runtime, :native_accelerators, original) end)
    :ok
  end

  test "the accelerator inventory is read from configuration" do
    config = NativeBridge.config()

    assert is_map(config)
    assert Map.has_key?(config, @accelerator)
    assert Keyword.get(config[@accelerator], :path) == "priv/native/rrm_native_jit"
  end

  test "the owner application is configurable and defaults to the runtime" do
    assert NativeBridge.owner_app() == :tiannara_runtime
  end

  test "an unconfigured accelerator is reported as not configured" do
    Application.put_env(:tiannara_runtime, :native_accelerators, %{})

    assert NativeBridge.status(:never_configured_accelerator) == :not_configured
  end

  test "a configured accelerator without a native artifact is reported as missing" do
    Application.put_env(:tiannara_runtime, :native_accelerators, %{
      @accelerator => [path: "priv/native/definitely_absent_accelerator"]
    })

    assert NativeBridge.status(@accelerator) == :missing
  end

  test "the native path resolves against the running application, not a hardcoded atom" do
    assert {:ok, path} = NativeBridge.native_path(@accelerator)
    assert String.contains?(path, "tiannara_runtime")
    assert String.ends_with?(path, "priv/native/rrm_native_jit")
  end

  test "loading an absent accelerator fails closed with a typed reason" do
    Application.put_env(:tiannara_runtime, :native_accelerators, %{
      @accelerator => [path: "priv/native/definitely_absent_accelerator"]
    })

    assert {:error, {:nif_missing, path}} = NativeBridge.load(@accelerator)
    assert String.ends_with?(path, "definitely_absent_accelerator")
  end

  test "calling an unconfigured accelerator fails closed" do
    Application.put_env(:tiannara_runtime, :native_accelerators, %{})

    assert {:error, :nif_not_configured} = NativeBridge.call(@accelerator, :compile_and_optimize, [{}, :cpu])
  end

  test "calling a configured but absent accelerator fails closed" do
    Application.put_env(:tiannara_runtime, :native_accelerators, %{
      @accelerator => [path: "priv/native/definitely_absent_accelerator"]
    })

    assert {:error, :nif_unavailable} = NativeBridge.call(@accelerator, :compile_and_optimize, [{}, :cpu])
  end

  test "the phase bridges expose their accelerator status and fail closed" do
    assert Tiannara.Phase18.RRM.NativeBridge.accelerator_status() in [
             :available,
             :missing,
             :not_loaded,
             :not_configured
           ]

    assert {:error, reason} = Tiannara.Phase18.RRM.NativeBridge.jit_compile(%{}, :cpu)
    assert reason in [:nif_not_configured, :nif_unavailable]
  end
end
