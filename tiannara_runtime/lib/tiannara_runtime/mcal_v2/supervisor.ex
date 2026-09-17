defmodule Tiannara.MCALv2.Supervisor do
  @moduledoc """
  MCAL v2: Supervisor.
  
  Manages the Recursive Identity Tree and the orchestration loop.
  """
  
  use Supervisor
  require Logger

  def start_link(init_state \\ []) do
    Supervisor.start_link(__MODULE__, init_state, name: __MODULE__)
  end

  @impl true
  def init(_) do
    Logger.info("🧬 [MCAL v2] Recursive Identity Engine booting...")
    
    children = [
      Tiannara.MCALv2.IdentityTree
    ]

    Supervisor.init(children, strategy: :rest_for_one)
  end
end
