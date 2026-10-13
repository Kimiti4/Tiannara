defmodule Tiannara.ASC.Crucible.Supervisor do
  use Tiannara.Stub, subsystem: :asc, phase: "Omega+", priority: :high

  def run(project) do
    stub_result(:run, [project], {:ok, :stub})
  end
end
