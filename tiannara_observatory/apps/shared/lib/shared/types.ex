defmodule Shared.TelemetryEvent do
  defstruct [
    :id,
    :source,
    :version,
    :timestamp,
    :clock,
    :provenance,
    :signature,
    :schema,
    :domain,
    :classification,
    :replay_id,
    :lineage,
    :compression,
    :retention,
    :certification,
    :payload
  ]

  @type clock :: %{wall_time: integer(), logical: integer()}
  @type provenance :: %{
          producer: String.t(),
          pipeline: [map()],
          generation: integer(),
          constitution: String.t(),
          operator: String.t() | nil
        }
  @type certification :: %{
          status: String.t(),
          checked_at: String.t(),
          checked_by: String.t(),
          confidence: float(),
          reasons: [String.t()]
        }
  @type t :: %__MODULE__{
          id: String.t(),
          source: String.t(),
          version: String.t(),
          timestamp: String.t(),
          clock: clock(),
          provenance: provenance(),
          signature: map() | nil,
          schema: String.t(),
          domain: String.t(),
          classification: map(),
          replay_id: String.t() | nil,
          lineage: map() | nil,
          compression: String.t(),
          retention: String.t(),
          certification: certification() | nil,
          payload: map()
        }
end

defmodule Shared.WidgetConfig do
  defstruct [
    :widget_id,
    :spec_version,
    :name,
    :description,
    :owner,
    :data_sources,
    :refresh_policy,
    :replay_compatibility,
    :certification_requirements,
    :security_classification,
    :interaction_policy,
    :visualization,
    :size
  ]
end

defmodule Shared.LayoutConfig do
  defstruct [:dashboard_id, :version, :title, :widgets, :layout, :created_at, :updated_at]
end

defmodule Shared.Operator do
  defstruct [:operator_id, :role, :credentials, :assigned_at]
end
