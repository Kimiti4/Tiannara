defmodule Tiannara.Council.Supervisor do
  use Supervisor

  def start_link(init_arg), do: Supervisor.start_link(__MODULE__, init_arg, name: __MODULE__)

  @impl true
  def init(_init_arg) do
    children = [
      Tiannara.Council.AuditLog,
      Tiannara.Council.ConstitutionRepository,
      Tiannara.Council.PolicyRegistry,
      Tiannara.Council.HumanApprovalQueue,
      Tiannara.Council.AmendmentEngine,
      Tiannara.Council.ConstitutionalMonitor,
      Tiannara.Council
    ]

    Supervisor.init(children, strategy: :rest_for_one)
  end
end
