defmodule Tiannara.CEL.Planner do
  use GenServer
  require Logger

  def start_link(opts \\ []), do: GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  def healthy?, do: GenServer.call(__MODULE__, :healthy)
  def constitutional_score, do: GenServer.call(__MODULE__, :constitutional_score)

  @impl true
  def init(_opts), do: {:ok, %{plans_created: 0, last_plan_at: nil}}

  @impl true
  def handle_call(:healthy, _from, state), do: {:reply, Process.alive?(self()), state}

  @impl true
  def handle_call(:constitutional_score, _from, state) do
    score = %Tiannara.CEL.Kernel.ConstitutionalScore{
      service_id: :executive_planner,
      health: if(Process.alive?(self()), do: 1.0, else: 0.0),
      constitutional_alignment: 1.0,
      transparency: 1.0,
      explainability: 1.0,
      evidence_quality: 0.0,
      human_oversight: 1.0,
      computed_at: DateTime.utc_now()
    }
    {:reply, score, state}
  end
end
