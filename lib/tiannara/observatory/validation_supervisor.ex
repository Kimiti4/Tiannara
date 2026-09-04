defmodule Tiannara.Observatory.ValidationSupervisor do
  use DynamicSupervisor

  def start_link(init_arg) do
    DynamicSupervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  @impl true
  def init(_init_arg) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  def start_campaign(%Tiannara.Observatory.ValidationCampaign{} = campaign) do
    DynamicSupervisor.start_child(__MODULE__, {Tiannara.Observatory.ValidationCampaign, campaign})
  end
end
