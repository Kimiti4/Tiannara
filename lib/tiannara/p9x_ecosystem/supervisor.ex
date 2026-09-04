defmodule Tiannara.P9XEcosystem.Supervisor do
  @moduledoc "P9X Ecological Governance — manages P9X subsystem"
  use Supervisor
  require Logger

  def start_link(opts \\ []) do
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    children = [Tiannara.P9X.Supervisor]
    Supervisor.init(children, strategy: :one_for_one)
  end
end

defmodule Tiannara.P9X.Supervisor do
  use Supervisor
  require Logger
  def start_link(opts), do: Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  @impl true
  def init(_opts) do
    Logger.info("[P9X] Supervisor initialized")
    Supervisor.init([], strategy: :one_for_one)
  end
end
