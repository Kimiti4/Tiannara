defmodule Tiannara.ASC.Observatory.Supervisor do
  @moduledoc "Supervisor for the ASC Project Observatory subsystem."

  use Supervisor

  def start_link(opts \\ []) do
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    children = [
      Tiannara.ASC.Observatory.ProjectObservatory,
    ]
    Supervisor.init(children, strategy: :one_for_one)
  end
end
