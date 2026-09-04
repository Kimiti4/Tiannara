defmodule Mix.Tasks.PhaseOmega.Scan do
  use Mix.Task

  @shortdoc "Run Phase Ω full system scan and print report"

  def run(_args) do
    Mix.Task.run("app.start")

    Tiannara.PhaseOmega.Activator.bootstrap()
    :init.stop()
  end
end
