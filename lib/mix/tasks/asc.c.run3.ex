defmodule Mix.Tasks.Asc.C.Run3 do
  use Mix.Task

  @shortdoc "Run the ASC-AE-003 tradeoff-aware engineering mission (contract K-AE003)"

  def run(_args) do
    mission = Tiannara.ASC.CMissions.AE003.Mission.spec()
    Tiannara.ASC.CMissions.RunnerV3.run(mission)
  end
end