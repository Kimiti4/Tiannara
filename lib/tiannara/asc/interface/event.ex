defmodule Tiannara.ASC.Interface.Event do
  @moduledoc """
  Interface Event — represents an event stream definition (pub/sub topic, message queue).

  Events enable asynchronous communication between services and are first-class
  citizens in interface evolution. They define:
  - Event semantics (what happened)
  - Producer/consumer relationships
  - Delivery guarantees (at_least_once, exactly_once, at_most_once)
  - Schema definitions (event payload structure)

  Events evolve through mutations like merge, split, delivery guarantee changes.

  ## Example

      iex> event = %Tiannara.ASC.Interface.Event{
      ...>   id: "user.created",
      ...>   name: "User Created",
      ...>   producer: "user_service",
      ...>   consumers: ["analytics_service", "notification_service"],
      ...>   schema: %{type: "object", properties: %{"user_id" => %{"type" => "string"}}},
      ...>   delivery_guarantee: :at_least_once
      ...> }

  """

  @derive Jason.Encoder
  defstruct [
    # Identity
    id: nil,
    name: nil,

    # Topology
    producer: nil,       # Service that emits this event
    consumers: [],       # List of services that consume this event

    # Schema
    schema: %{},         # Event payload schema

    # Delivery semantics
    delivery_guarantee: :at_least_once,  # :at_least_once, :exactly_once, :at_most_once
    partitioning_strategy: :random,      # :random, :key_based, :round_robin

    # Evolution metadata
    created_at: nil,
    modified_at: nil,
    parent_event_id: nil  # For tracking event lineage during evolution
  ]

  @typedoc "Interface event structure"
  @type t :: %__MODULE__{
          id: String.t() | nil,
          name: String.t() | nil,
          producer: String.t() | nil,
          consumers: [String.t()],
          schema: map(),
          delivery_guarantee: atom(),
          partitioning_strategy: atom(),
          created_at: DateTime.t() | nil,
          modified_at: DateTime.t() | nil,
          parent_event_id: String.t() | nil
        }

  @doc """
  Create a new event from workflow step.

  Infers event name and schema from the workflow description.

  ## Parameters

  - `workflow` — Workflow struct from ImplementationPlan
  - `step_index` — Index of the workflow step that triggers this event

  ## Examples

      iex> workflow = %{name: "Process Payment", steps: [%{}, %{}]}
      iex> event = Tiannara.ASC.Interface.Event.from_workflow(workflow, 1)
      iex> String.contains?(event.id, "process_payment")
      true

  """
  def from_workflow(workflow, step_index) do
    event_name = "#{workflow.name || "event"}.step_#{step_index}"
    id = Macro.underscore(event_name) |> String.replace(".", "_")

    %__MODULE__{
      id: id,
      name: event_name,
      producer: infer_producer(workflow),
      consumers: [],
      schema: %{type: "object", properties: %{}},
      delivery_guarantee: :at_least_once,
      partitioning_strategy: :random,
      created_at: DateTime.utc_now(),
      modified_at: DateTime.utc_now(),
      parent_event_id: nil
    }
  end

  @doc """
  Merge two events into a single consolidated event.

  Combines consumers and schemas from both events.
  """
  def merge(%__MODULE__{} = event1, %__MODULE__{} = event2) do
    merged_schema = merge_schemas(event1.schema, event2.schema)
    merged_consumers = Enum.uniq(event1.consumers ++ event2.consumers)

    %__MODULE__{
      id: "#{event1.id}_#{event2.id}",
      name: "#{event1.name} + #{event2.name}",
      producer: event1.producer,
      consumers: merged_consumers,
      schema: merged_schema,
      delivery_guarantee: select_stricter_guarantee(event1.delivery_guarantee, event2.delivery_guarantee),
      partitioning_strategy: event1.partitioning_strategy,
      created_at: DateTime.utc_now(),
      modified_at: DateTime.utc_now(),
      parent_event_id: nil
    }
  end

  @doc """
  Split an event into multiple specialized events.

  Example: user.updated → user.profile_updated, user.settings_updated
  """
  def split(%__MODULE__{} = event, split_strategy) do
    case split_strategy do
      :by_consumer ->
        # Create separate events for each consumer
        Enum.map(event.consumers, fn consumer ->
          %__MODULE__{
            event
            | id: "#{event.id}_for_#{consumer}",
              consumers: [consumer],
              modified_at: DateTime.utc_now()
          }
        end)

      :by_field ->
        # Split based on schema fields
        properties = Map.get(event.schema, :properties, %{})
        field_list = Map.keys(properties)
        mid = div(length(field_list), 2)
        {fields1, fields2} = Enum.split(field_list, mid)

        schema1 = put_in(event.schema, [:properties], Map.take(properties, fields1))
        schema2 = put_in(event.schema, [:properties], Map.take(properties, fields2))

        [
          %{event | id: "#{event.id}_part1", schema: schema1, modified_at: DateTime.utc_now()},
          %{event | id: "#{event.id}_part2", schema: schema2, modified_at: DateTime.utc_now()}
        ]

      _ ->
        [event]
    end
  end

  @doc """
  Change delivery guarantee.

  Upgrades or downgrades the delivery semantics.
  """
  def change_delivery_guarantee(%__MODULE__{} = event, new_guarantee) do
    %__MODULE__{
      event
      | delivery_guarantee: new_guarantee,
        modified_at: DateTime.utc_now()
    }
  end

  @doc """
  Add a consumer to the event.
  """
  def add_consumer(%__MODULE__{} = event, consumer) do
    if consumer not in event.consumers do
      %__MODULE__{
        event
        | consumers: event.consumers ++ [consumer],
          modified_at: DateTime.utc_now()
      }
    else
      event
    end
  end

  @doc """
  Remove a consumer from the event.
  """
  def remove_consumer(%__MODULE__{} = event, consumer) do
    %__MODULE__{
      event
      | consumers: List.delete(event.consumers, consumer),
        modified_at: DateTime.utc_now()
    }
  end

  @doc """
  Calculate event complexity score.

  Based on number of consumers, schema size, and delivery guarantee strictness.
  """
  def complexity_score(%__MODULE__{} = event) do
    consumer_complexity = length(event.consumers) * 0.3
    schema_complexity = calculate_schema_complexity(event.schema) * 0.4
    guarantee_complexity = delivery_guarantee_weight(event.delivery_guarantee) * 0.3

    Float.round(consumer_complexity + schema_complexity + guarantee_complexity, 2)
  end

  # ---------------------------------------------------------------------------
  # Private helpers
  # ---------------------------------------------------------------------------

  defp infer_producer(workflow) do
    # Extract producer from workflow name or default
    case workflow.name do
      nil -> "unknown_service"
      name ->
        name
        |> String.downcase()
        |> String.replace(" ", "_")
        |> String.replace(~r/_service$/, "")
        |> Kernel.<>("_service")
    end
  end

  defp merge_schemas(schema1, schema2) do
    # Simple schema merge - would be enhanced with proper JSON Schema merging
    properties1 = Map.get(schema1, :properties, %{})
    properties2 = Map.get(schema2, :properties, %{})

    merged_properties = Map.merge(properties1, properties2)
    Map.put(schema1, :properties, merged_properties)
  end

  defp select_stricter_guarantee(guarantee1, guarantee2) do
    # Priority: exactly_once > at_least_once > at_most_once
    priorities = %{exactly_once: 3, at_least_once: 2, at_most_once: 1}

    if (priorities[guarantee1] || 0) >= (priorities[guarantee2] || 0) do
      guarantee1
    else
      guarantee2
    end
  end

  defp calculate_schema_complexity(schema) do
    properties = Map.get(schema, :properties, %{})
    length(Map.keys(properties)) * 0.1
  end

  defp delivery_guarantee_weight(:exactly_once), do: 1.0
  defp delivery_guarantee_weight(:at_least_once), do: 0.7
  defp delivery_guarantee_weight(:at_most_once), do: 0.4
  defp delivery_guarantee_weight(_), do: 0.5
end
