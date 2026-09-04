defmodule Tiannara.Ctl.CausalRegistry do
  use Tiannara.Stub, subsystem: :ctl, phase: "Omega+", priority: :high

  def get_branch(branch_id) do
    stub_result(:get_branch, [branch_id], {:ok, %{stress: 0.0}})
  end
end
