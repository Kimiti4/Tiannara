defmodule Tiannara.Domains.Extruder do
  @moduledoc """
  The semantic grounding interface. Translates domain knowledge from Tiannara 
  worlds into deployable Base Reality blueprints.
  """

  @type blueprint :: %{
          domain: atom(),
          status: :success | :failed,
          schematics: String.t(),
          confidence: float()
        }

  @callback extract_blueprint(
              intent :: atom(),
              world_context :: map(),
              discoveries :: list()
            ) :: blueprint()

  @doc """
  Dispatcher for the CommandLoom. Routes the request to the specific domain 
  extruder, fetching necessary world context.
  """
  def extract_blueprint(domain, primary_intent) do
    module = domain_module(domain)
    
    # In a full deployment, these would fetch from the active world state/ROS.
    world_context = %{bias: 1.0}
    discoveries = []
    
    module.extract_blueprint(primary_intent, world_context, discoveries)
  end

  defp domain_module(:engineering), do: Tiannara.Domains.Extruder.Engineering
  defp domain_module(:energy), do: Tiannara.Domains.Extruder.Energy
  defp domain_module(:computation), do: Tiannara.Domains.Extruder.Computation
  
  # Fallback to engineering for unsupported domains during phased rollout
  defp domain_module(_), do: Tiannara.Domains.Extruder.Engineering
end
