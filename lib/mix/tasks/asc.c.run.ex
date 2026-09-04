defmodule Mix.Tasks.Asc.C.Run do
  @moduledoc """
  Executes the ASC-AE-001 Autonomous Engineering Loop (C2-C6).

  Requires a C1 baseline at priv/asc/missions/ASC-AE-001/baseline.eterm
  (capture with `mix asc.bench.boot`).
  """

  use Mix.Task

  @shortdoc "Run ASC Milestone C autonomous engineering mission"

  @impl true
  def run(_args) do
    baseline_path = "priv/asc/missions/ASC-AE-001/baseline.eterm"

    unless File.exists?(baseline_path) do
      Mix.shell().error("C1 baseline missing. Run `mix asc.bench.boot` first.")
      exit({:shutdown, 1})
    end

    Tiannara.ASC.CMissions.Runner.run(baseline_path)
  end
end