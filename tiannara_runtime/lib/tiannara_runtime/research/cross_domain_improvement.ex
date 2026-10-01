defmodule TiannaraRuntime.Research.CrossDomainImprovement do
  @moduledoc """
  Aggregates certified discoveries from any Tiannara research domain into an
  improvement proposal without assuming that mathematics is the only source.

  Mathematics can certify formal claims; domain evidence supplies applicability.
  ACL/OAVL/CEL and human authorization remain independent gates.
  """

  @domains ~w(physics biology chemistry cybernetics computation energy materials economics control_systems information robotics ai cognition ecology medicine astronomy social_systems manufacturing transportation agriculture earth_systems)

  def propose(discoveries, target_system) when is_list(discoveries) do
    valid =
      Enum.filter(discoveries, fn discovery ->
        Map.get(discovery, :domain) in @domains and
        Map.get(discovery, :certification_status) == :certified and
        Map.get(discovery, :evidence) != nil
      end)

    {:ok, %{target_system: target_system, discoveries: valid,
            status: if(valid == [], do: :no_certified_discovery, else: :evidence_assembled),
            implementation_allowed: false}}
  end

  def propose(_, _), do: {:error, :discoveries_required}
end
