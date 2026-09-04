defmodule Tiannara.CEL.Models.CivilizationalEvent do
  defstruct [
    :id,
    :origin,
    :type,
    :raw_payload,
    :mission_id,
    :priority,
    :evidence,
    :confidence,
    :urgency,
    :impact,
    :risk,
    :resource_cost,
    :timestamp,
    :routing_destination,
    affected_domains: [],
    related_entities: [],
    dependencies: [],
    lineage: []
  ]
end
