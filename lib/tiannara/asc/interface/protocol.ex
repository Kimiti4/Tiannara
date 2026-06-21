defmodule Tiannara.ASC.Interface.Protocol do
  @moduledoc """
  Interface Protocol — represents a communication protocol specification (REST, GraphQL, gRPC, MCP, PubSub).

  Protocols define the transport and interaction patterns for interfaces. They evolve
  through mutations like protocol switching (REST → GraphQL), capability addition,
  and hybrid topology formation.

  ## Supported Protocol Types

  - `:rest` — RESTful HTTP APIs
  - `:graphql` — GraphQL query/mutation/subscription APIs
  - `:grpc` — gRPC remote procedure calls
  - `:mcp` — Model Context Protocol (agent-tool interface)
  - `:pubsub` — Publish/subscribe event streaming
  - `:beam` — BEAM message passing (inter-process)

  ## Example

      iex> protocol = %Tiannara.ASC.Interface.Protocol{
      ...>   id: "rest_api_v1",
      ...>   type: :rest,
      ...>   capabilities: [:crud, :filtering, :pagination],
      ...>   fitness: 0.85
      ...> }

  """

  @derive Jason.Encoder
  defstruct [
    # Identity
    id: nil,
    type: nil,  # :rest, :graphql, :grpc, :mcp, :pubsub, :beam

    # Capabilities
    capabilities: [],  # List of protocol-specific capabilities

    # Evolution metadata
    fitness: 0.0,
    created_at: nil,
    modified_at: nil,
    parent_protocol_id: nil  # For tracking protocol lineage during evolution
  ]

  @typedoc "Interface protocol structure"
  @type t :: %__MODULE__{
          id: String.t() | nil,
          type: atom() | nil,
          capabilities: [atom()],
          fitness: float(),
          created_at: DateTime.t() | nil,
          modified_at: DateTime.t() | nil,
          parent_protocol_id: String.t() | nil
        }

  @doc """
  Create a new protocol from implementation plan architecture style.

  Maps architecture styles to appropriate protocols.

  ## Parameters

  - `architecture_style` — Architecture style from ImplementationPlan

  ## Examples

      iex> protocol = Tiannara.ASC.Interface.Protocol.from_architecture(:microservice)
      iex> protocol.type
      :rest

  """
  def from_architecture(architecture_style) do
    {type, capabilities} = case architecture_style do
      :microservice ->
        {:rest, [:crud, :service_discovery, :load_balancing]}

      :event_driven ->
        {:pubsub, [:publish, :subscribe, :event_ordering]}

      :actor_based ->
        {:beam, [:message_passing, :supervision, :distribution]}

      :api_gateway ->
        {:rest, [:routing, :authentication, :rate_limiting]}

      :graphql_federation ->
        {:graphql, [:query, :mutation, :subscription, :federation]}

      _ ->
        {:rest, [:crud]}
    end

    %__MODULE__{
      id: "#{Atom.to_string(type)}_protocol",
      type: type,
      capabilities: capabilities,
      fitness: 0.0,
      created_at: DateTime.utc_now(),
      modified_at: DateTime.utc_now(),
      parent_protocol_id: nil
    }
  end

  @doc """
  Switch protocol type (e.g., REST → GraphQL).

  Migrates capabilities to the new protocol type.
  """
  def switch_type(%__MODULE__{} = protocol, new_type) do
    new_capabilities = migrate_capabilities(protocol.capabilities, protocol.type, new_type)

    %__MODULE__{
      protocol
      | type: new_type,
        capabilities: new_capabilities,
        modified_at: DateTime.utc_now(),
        parent_protocol_id: protocol.id
    }
  end

  @doc """
  Add a capability to the protocol.

  Example: Add :pagination to REST protocol
  """
  def add_capability(%__MODULE__{} = protocol, capability) do
    if capability not in protocol.capabilities do
      %__MODULE__{
        protocol
        | capabilities: protocol.capabilities ++ [capability],
          modified_at: DateTime.utc_now()
      }
    else
      protocol
    end
  end

  @doc """
  Remove a capability from the protocol.
  """
  def remove_capability(%__MODULE__{} = protocol, capability) do
    %__MODULE__{
      protocol
      | capabilities: List.delete(protocol.capabilities, capability),
        modified_at: DateTime.utc_now()
    }
  end

  @doc """
  Merge two protocols into a hybrid protocol.

  Creates a multi-protocol interface (e.g., REST + GraphQL).
  """
  def merge(%__MODULE__{} = protocol1, %__MODULE__{} = protocol2) do
    if protocol1.type != protocol2.type do
      # Hybrid protocol
      %__MODULE__{
        id: "#{protocol1.id}_#{protocol2.id}",
        type: :hybrid,
        capabilities: Enum.uniq(protocol1.capabilities ++ protocol2.capabilities),
        fitness: 0.0,
        created_at: DateTime.utc_now(),
        modified_at: DateTime.utc_now(),
        parent_protocol_id: nil
      }
    else
      # Same type - just merge capabilities
      %__MODULE__{
        protocol1
        | capabilities: Enum.uniq(protocol1.capabilities ++ protocol2.capabilities),
          modified_at: DateTime.utc_now()
      }
    end
  end

  @doc """
  Calculate protocol complexity score.

  Based on number of capabilities and protocol type sophistication.
  """
  def complexity_score(%__MODULE__{} = protocol) do
    capability_complexity = length(protocol.capabilities) * 0.3
    type_complexity = protocol_type_weight(protocol.type) * 0.7

    Float.round(capability_complexity + type_complexity, 2)
  end

  @doc """
  Get recommended protocol for use case.

  Suggests optimal protocol based on requirements.
  """
  def recommend(use_case) do
    case use_case do
      :real_time_updates ->
        %__MODULE__{type: :pubsub, capabilities: [:publish, :subscribe]}

      :complex_queries ->
        %__MODULE__{type: :graphql, capabilities: [:query, :mutation, :introspection]}

      :high_performance_rpc ->
        %__MODULE__{type: :grpc, capabilities: [:streaming, :protobuf, :bidirectional]}

      :agent_tool_interface ->
        %__MODULE__{type: :mcp, capabilities: [:tools, :resources, :prompts]}

      :simple_crud ->
        %__MODULE__{type: :rest, capabilities: [:crud]}

      _ ->
        %__MODULE__{type: :rest, capabilities: [:crud]}
    end
  end

  # ---------------------------------------------------------------------------
  # Private helpers
  # ---------------------------------------------------------------------------

  defp migrate_capabilities(capabilities, from_type, to_type) do
    # Map capabilities between protocol types
    case {from_type, to_type} do
      {:rest, :graphql} ->
        # REST CRUD → GraphQL queries/mutations
        [:query, :mutation] ++ Enum.filter(capabilities, &(&1 in [:authentication, :validation]))

      {:rest, :grpc} ->
        # REST → gRPC methods
        [:rpc, :streaming] ++ Enum.filter(capabilities, &(&1 in [:authentication]))

      {:pubsub, :beam} ->
        # PubSub → BEAM messages
        [:message_passing, :pattern_matching]

      _ ->
        capabilities  # Keep original capabilities if no migration rule
    end
  end

  defp protocol_type_weight(:graphql), do: 0.9
  defp protocol_type_weight(:grpc), do: 0.85
  defp protocol_type_weight(:mcp), do: 0.8
  defp protocol_type_weight(:pubsub), do: 0.75
  defp protocol_type_weight(:rest), do: 0.6
  defp protocol_type_weight(:beam), do: 0.7
  defp protocol_type_weight(:hybrid), do: 1.0
  defp protocol_type_weight(_), do: 0.5
end
