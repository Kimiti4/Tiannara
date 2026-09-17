defmodule Tiannara.A10.Supervisor do
  use Supervisor

  def start_link(init_arg) do
    Supervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  def init(_init_arg) do
    children = [
      Tiannara.A10.AttractorMemory,
      Tiannara.A10.DriftTensor,
      Tiannara.A10.AttractorAnalyzer,
      Tiannara.A10.Sampler,
      Tiannara.A10.AdvisoryEmitter
    ]
    Supervisor.init(children, strategy: :rest_for_one)
  end
end
