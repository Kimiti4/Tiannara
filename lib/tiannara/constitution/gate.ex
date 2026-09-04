defmodule Tiannara.Constitution.Gate do
  @moduledoc """
  The constitutional gate. Opens only when every invariant passes. A closed
  gate must block downstream certification — capability must never outrun
  verification.

  Constitutional basis: "Capability must never outpace verification",
  "Truth has priority over confidence."
  """

  alias Tiannara.Constitution.SuiteRun

  def verdict(%SuiteRun{all_passed: true}), do: :gate_open
  def verdict(%SuiteRun{} = run), do: {:gate_closed, run.failed}
end