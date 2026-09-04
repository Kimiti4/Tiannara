defmodule Tiannara.Twp.SurvivabilityEstimator do
  use Tiannara.Stub, subsystem: :twp, phase: "Omega+", priority: :high

  def estimate(branch_state) do
    stub_result(:estimate, [branch_state], 0.5)
  end
end
