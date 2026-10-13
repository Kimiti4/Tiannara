defmodule Tiannara.Ctl.BranchValidatorTest do
  use ExUnit.Case, async: false

  alias Tiannara.CTL.CausalRegistry
  alias Tiannara.Ctl.BranchValidator

  setup do
    suffix = System.unique_integer([:positive])
    %{suffix: suffix}
  end

  test "validates a merge of registered branches within the stress threshold", %{suffix: s} do
    assert {:ok, _} = CausalRegistry.register_branch("bv-a-#{s}", %{origin: :test}, 0.2)
    assert {:ok, _} = CausalRegistry.register_branch("bv-b-#{s}", %{origin: :test}, 0.3)
    assert {:ok, :valid} = BranchValidator.validate_merge("bv-a-#{s}", "bv-b-#{s}")
  end

  test "rejects a merge whose combined causal stress exceeds the threshold", %{suffix: s} do
    assert {:ok, _} = CausalRegistry.register_branch("bv-c-#{s}", %{origin: :test}, 0.9)
    assert {:ok, _} = CausalRegistry.register_branch("bv-d-#{s}", %{origin: :test}, 0.8)
    assert {:error, :invalid_merge} = BranchValidator.validate_merge("bv-c-#{s}", "bv-d-#{s}")
  end

  test "D-B regression: unregistered branches fail closed (the aliased stub answered {:ok, :valid})",
       %{suffix: s} do
    assert {:error, :branch_not_found} =
             BranchValidator.validate_merge("bv-ghost-a-#{s}", "bv-ghost-b-#{s}")
  end

  test "validation targets the real CTL registry; the case-twin stub no longer exists" do
    assert {:module, _} = Code.ensure_loaded(CausalRegistry)
    refute function_exported?(CausalRegistry, :__tiannara_stub__, 0)
    assert function_exported?(CausalRegistry, :get_branch, 1)

    # The similarly cased stub was deleted: on case-insensitive filesystems
    # its beam file collided with the real module's (capability ledger D-B),
    # so exactly one of the two survived each compile — non-deterministically.
    #
    # On case-insensitive filesystems (Windows), Code.ensure_loaded?/1 would
    # resolve the lowercase request to the sibling CTL beam and log a
    # loader-mismatch error from beam_load — check the loaded-modules list
    # instead (no load attempt, same assertion). Case-sensitive filesystems
    # keep the stronger probe (detects loadable-but-not-loaded too).
    if match?({:win32, _}, :os.type()) do
      loaded = Enum.map(:code.all_loaded(), &elem(&1, 0))
      refute Tiannara.Ctl.CausalRegistry in loaded
    else
      refute Code.ensure_loaded?(Tiannara.Ctl.CausalRegistry)
    end
  end

  test "rejects out-of-range or invalid stress at registration" do
    assert {:error, :invalid_stress} =
             CausalRegistry.register_branch("bv-x", %{origin: :test}, 1.5)

    assert {:error, :invalid_stress} =
             CausalRegistry.register_branch("bv-y", %{origin: :test}, -0.1)

    assert {:error, :invalid_stress} =
             CausalRegistry.register_branch("bv-z", %{origin: :test}, "low")

    assert {:error, :invalid_branch_id} =
             CausalRegistry.register_branch("", %{origin: :test}, 0.5)
  end

  test "duplicate registration is refused (single canonical record)", %{suffix: s} do
    assert {:ok, _} = CausalRegistry.register_branch("bv-dup-#{s}", %{origin: :test}, 0.1)

    assert {:error, :already_registered} =
             CausalRegistry.register_branch("bv-dup-#{s}", %{origin: :test}, 0.2)
  end

  test "missing threshold configuration fails closed instead of using a built-in default",
       %{suffix: s} do
    assert {:ok, _} = CausalRegistry.register_branch("bv-t1-#{s}", %{origin: :test}, 0.1)
    assert {:ok, _} = CausalRegistry.register_branch("bv-t2-#{s}", %{origin: :test}, 0.2)

    original = Application.fetch_env!(:tiannara, :ctl_causal_stress_threshold)
    Application.delete_env(:tiannara, :ctl_causal_stress_threshold)
    on_exit(fn -> Application.put_env(:tiannara, :ctl_causal_stress_threshold, original) end)

    assert {:error, :threshold_configuration_absent} =
             BranchValidator.validate_merge("bv-t1-#{s}", "bv-t2-#{s}")
  end

  test "active branch count is measured evidence, not the removed 10_000 mock", %{suffix: s} do
    assert {:ok, _} = CausalRegistry.register_branch("bv-count-#{s}", %{origin: :test}, 0.1)
    assert {:ok, count} = CausalRegistry.get_active_branches()
    assert is_integer(count) and count >= 1
    refute count == 10_000
  end
end
