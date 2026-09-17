defmodule Tiannara.MCAL.Supervisor do
  @moduledoc """
  MCAL: Meta-Cognitive Abstraction Layer.
  
  The root supervisor for the MCAL OTP tree. MCAL acts as the
  adaptive reasoning compiler for evolving civilizations, deciding
  how cognition itself should be structured before execution happens.
  """
  
  use Supervisor
  require Logger

  def start_link(init_state \\ []) do
    Supervisor.start_link(__MODULE__, init_state, name: __MODULE__)
  end

  @impl true
  def init(_) do
    Logger.info("🧠 [MCAL] Meta-Cognitive Abstraction Layer booting...")
    
    children = [
      Tiannara.MCAL.Memory,
      Tiannara.MCAL.CognitiveKernel,
      # These components will be invoked functionally by the Kernel, 
      # but we can supervise stateful ones here if needed later.
      # For now, CognitiveKernel holds the active context.
    ]

    Supervisor.init(children, strategy: :rest_for_one)
  end
end
