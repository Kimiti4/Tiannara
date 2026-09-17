defmodule ObservatoryCore.Types.Widget do
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

  @type t :: %__MODULE__{
          widget_id: String.t(),
          spec_version: String.t(),
          name: String.t(),
          description: String.t(),
          owner: String.t(),
          data_sources: [map()],
          refresh_policy: map(),
          replay_compatibility: map(),
          certification_requirements: map(),
          security_classification: map(),
          interaction_policy: map(),
          visualization: map(),
          size: map()
        }

  def new(attrs \\ %{}) do
    struct!(__MODULE__, attrs)
  end
end
