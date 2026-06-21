defmodule Tiannara.Meta.Hardware.Supervisor do
  @moduledoc "Manages the life-cycle of the Horizon Scheduler and EHTC GenServers."
  use Supervisor

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    hsv_pool = [:hsv_alpha, :hsv_beta, :hsv_gamma]

    children = [
      # 1. Registry for EHTC cores
      {Registry, keys: :unique, name: Tiannara.HardwareRegistry},
      
      # 2. The Horizon Scheduler (Load Balancer)
      {Tiannara.Meta.Hardware.HorizonScheduler, [hsv_pool: hsv_pool]},
      
      # 3. The Event Horizon Tensor Cores (Workers)
      Supervisor.child_spec(
        {Tiannara.Meta.Hardware.EventHorizonTensorCore, [hsv_id: :hsv_alpha]}, 
        id: :ehtc_alpha
      ),
      Supervisor.child_spec(
        {Tiannara.Meta.Hardware.EventHorizonTensorCore, [hsv_id: :hsv_beta]}, 
        id: :ehtc_beta
      ),
      Supervisor.child_spec(
        {Tiannara.Meta.Hardware.EventHorizonTensorCore, [hsv_id: :hsv_gamma]}, 
        id: :ehtc_gamma
      )
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
