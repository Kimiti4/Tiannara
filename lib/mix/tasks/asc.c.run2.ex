defmodule Mix.Tasks.Asc.C.Run2 do
  use Mix.Task

  @shortdoc "Run the ASC-AE-002 evidence-ranked discrimination mission"

  def run(_args) do
    mission = Tiannara.ASC.CMissions.AE002.Mission.spec()
    Tiannara.ASC.CMissions.RunnerV2.run(mission)
  end
end