defmodule Tiannara.Engineering.EngineeringSupervisor do
  use Supervisor

  def start_link(opts \\ []) do
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    children = [
      {Tiannara.Engineering.EngineeringSynthesisEngine, []},
      {Tiannara.Engineering.ProposalRegistry, []},
      {Tiannara.Engineering.RootCauseAnalyzer, []},
      {Tiannara.Engineering.ProposalGenerator, []},
      {Tiannara.VerificationAuthority, []}
    ]
    Supervisor.init(children, strategy: :one_for_one, max_restarts: 5, max_seconds: 60)
  end
end
