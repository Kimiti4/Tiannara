defmodule Tiannara.CEL.Kernel.ConstitutionalScoreRemediationTest do
  use ExUnit.Case, async: true

  alias Tiannara.CEL.Kernel.ConstitutionalScore

  test "default score is fail-closed" do
    score = ConstitutionalScore.default(:test_service)

    assert ConstitutionalScore.aggregate(score) == 0.0
    refute ConstitutionalScore.boot_ready?(score)
  end
end
