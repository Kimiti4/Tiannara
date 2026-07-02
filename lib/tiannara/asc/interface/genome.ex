defmodule Tiannara.ASC.Interface.Genome do
  @moduledoc """
  Interface Genome — represents the DNA of an interface ecosystem.

  Encodes architectural interface decisions as evolvable genes, supporting:
  - REST APIs (contracts/endpoints)
  - Event streams (pub/sub topics)
  - Protocols (GraphQL, gRPC, agent protocols)
  - Data schemas (type definitions)
  - BEAM message contracts (inter-process communication)

  This genome evolves through genetic algorithms to discover optimal
  interface architectures based on multi-objective fitness scoring.

  ## Fields

  ### Core Identity
  - `genome_id` — Unique identifier for this genome
  - `generation` — Evolution generation number (starts at 0)
  - `fitness` — Multi-objective fitness score (0.0 to 1.0)

  ### Interface Contracts (protocol-agnostic)
  - `contracts` — List of interface contracts (REST endpoints, GraphQL queries, gRPC methods)
  - `events` — List of event stream definitions (topics, pub/sub)
  - `protocols` — List of protocol specifications (REST, GraphQL, gRPC, agent protocols)
  - `schemas` — List of data schema definitions
  - `interfaces` — List of BEAM message contracts / inter-process interfaces

  ### Production Readiness
  - `auth_models` — Authentication/authorization models
  - `versioning_strategy` — API versioning approach (:url_path, :header, :none)
  - `compatibility_mode` — Backward compatibility mode (:backward, :forward, :breaking)

  ### Deployment Topology
  - `deployment_units` — List of deployable units derived from interfaces
  - `scaling_policies` — Scaling strategies per deployment unit
  - `network_topology` — Network architecture description

  ### Evolution Metadata
  - `blueprints_used` — List of blueprint patterns applied
  - `policies_applied` — List of policies enforced
  - `deployment_target` — Target deployment platform

  ## Example

      iex> genome = Tiannara.ASC.Interface.Genome.new()
      iex> genome.generation
      0

  """

  @derive Jason.Encoder
  defstruct [
    # Core identity
    genome_id: nil,
    generation: 0,
    fitness: 0.0,

    # Interface contracts (protocol-agnostic)
    contracts: [],
    events: [],
    protocols: [],
    schemas: [],
    interfaces: [],

    # Production readiness
    auth_models: [],
    versioning_strategy: :url_path,
    compatibility_mode: :backward,

    # Deployment topology
    deployment_units: [],
    scaling_policies: [],
    network_topology: nil,

    # Evolution metadata
    blueprints_used: [],
    policies_applied: [],
    deployment_target: "docker-compose"
  ]

  @typedoc "Interface genome structure"
  @type t :: %__MODULE__{
          genome_id: String.t() | nil,
          generation: non_neg_integer(),
          fitness: float(),
          contracts: [map()],
          events: [map()],
          protocols: [map()],
          schemas: [map()],
          interfaces: [map()],
          auth_models: [map()],
          versioning_strategy: atom(),
          compatibility_mode: atom(),
          deployment_units: [map()],
          scaling_policies: [map()],
          network_topology: String.t() | nil,
          blueprints_used: [String.t()],
          policies_applied: [String.t()],
          deployment_target: String.t()
        }

  @doc """
  Create a new random interface genome.

  Generates a genome with randomized interface contracts, protocols,
  and configuration suitable for initial population seeding.

  ## Examples

      iex> genome = Tiannara.ASC.Interface.Genome.new()
      iex> is_binary(genome.genome_id)
      true
      iex> genome.generation
      0

  """
  def new do
    %__MODULE__{
      genome_id: generate_id(),
      generation: 0,
      fitness: 0.0,
      contracts: generate_random_contracts(),
      events: generate_random_events(),
      protocols: generate_random_protocols(),
      schemas: generate_random_schemas(),
      interfaces: [],
      auth_models: generate_random_auth(),
      versioning_strategy: random_versioning(),
      compatibility_mode: :backward,
      deployment_units: [],
      scaling_policies: [],
      network_topology: nil,
      blueprints_used: [],
      policies_applied: [],
      deployment_target: "docker-compose"
    }
  end

  @doc """
  Create a genome from ImplementationPlan capabilities.

  Extracts interface requirements from the implementation plan and
  generates an initial genome tailored to those requirements.

  ## Parameters

  - `plan` — ImplementationPlan struct containing capabilities and storage models

  ## Examples

      iex> plan = %ImplementationPlan{capabilities: [...], storage_models: [...]}
      iex> genome = Tiannara.ASC.Interface.Genome.from_plan(plan)
      iex> length(genome.contracts) > 0
      true

  """
  def from_plan(%Tiannara.ASC.Implementation.Plan{} = plan) do
    contracts = extract_contracts_from_capabilities(plan.capabilities)
    schemas = extract_schemas_from_storage_models(plan.storage_models)
    events = infer_events_from_workflows(plan.workflows)

    %__MODULE__{
      genome_id: generate_id(),
      generation: 0,
      fitness: 0.0,
      contracts: contracts,
      events: events,
      protocols: [%{type: :rest, version: "3.0.0"}],
      schemas: schemas,
      interfaces: [],
      auth_models: generate_default_auth(),
      versioning_strategy: :url_path,
      compatibility_mode: :backward,
      deployment_units: [],
      scaling_policies: [],
      network_topology: nil,
      blueprints_used: [],
      policies_applied: [],
      deployment_target: "docker-compose"
    }
  end

  @doc """
  Encode genome to map for serialization.

  Converts the genome struct into a plain map suitable for JSON encoding
  or ETS storage.

  ## Examples

      iex> genome = Tiannara.ASC.Interface.Genome.new()
      iex> map = Tiannara.ASC.Interface.Genome.encode(genome)
      iex> is_map(map)
      true

  """
  def encode(%__MODULE__{} = genome) do
    Map.from_struct(genome)
  end

  @doc """
  Decode map back to genome struct.

  Restores a genome from a previously encoded map.

  ## Examples

      iex> genome = Tiannara.ASC.Interface.Genome.new()
      iex> map = Tiannara.ASC.Interface.Genome.encode(genome)
      iex> restored = Tiannara.ASC.Interface.Genome.decode(map)
      iex> restored.genome_id == genome.genome_id
      true

  """
  def decode(map) when is_map(map) do
    struct(__MODULE__, map)
  end

  # ---------------------------------------------------------------------------
  # Private helpers
  # ---------------------------------------------------------------------------

  defp generate_id, do: UUID.uuid4()

  defp generate_random_contracts do
    services = ["users", "auth", "payments", "analytics", "notifications"]
    num_services = Enum.random(2..5)

    Enum.take_random(services, num_services)
    |> Enum.flat_map(fn service ->
      [
        %{
          id: "#{service}.create",
          method: :post,
          path: "/api/v1/#{service}",
          input_schema: %{type: "object"},
          output_schema: %{type: "object"},
          version: "v1"
        },
        %{
          id: "#{service}.list",
          method: :get,
          path: "/api/v1/#{service}",
          input_schema: %{},
          output_schema: %{type: "array"},
          version: "v1"
        },
        %{
          id: "#{service}.get",
          method: :get,
          path: "/api/v1/#{service}/{id}",
          input_schema: %{},
          output_schema: %{type: "object"},
          version: "v1"
        }
      ]
    end)
  end

  defp generate_random_events do
    topics = ["user.created", "payment.processed", "notification.sent"]
    num_topics = Enum.random(0..3)

    Enum.take_random(topics, num_topics)
    |> Enum.map(fn topic ->
      %{
        topic: topic,
        schema: %{type: "object"},
        delivery_guarantee: :at_least_once,
        consumers: ["analytics"],
        partitioning_strategy: :random
      }
    end)
  end

  defp generate_random_protocols do
    [%{type: :rest, version: "3.0.0"}]
  end

  defp generate_random_schemas do
    entities = ["User", "Payment", "Notification"]
    num_entities = Enum.random(1..3)

    Enum.take_random(entities, num_entities)
    |> Enum.map(fn entity ->
      %{
        name: entity,
        fields: [
          %{name: "id", type: "string", primary_key: true},
          %{name: "created_at", type: :datetime}
        ],
        version: "v1"
      }
    end)
  end

  defp generate_random_auth do
    auth_types = [:jwt, :oauth2, :api_key]
    [%{type: Enum.random(auth_types), enabled: true}]
  end

  defp generate_default_auth do
    [%{type: :jwt, enabled: true}]
  end

  defp random_versioning do
    Enum.random([:url_path, :header])
  end

  defp extract_contracts_from_capabilities(capabilities) do
    Enum.map(capabilities, fn cap ->
      %{
        id: String.downcase(String.replace(cap.name || "", " ", "_")),
        method: infer_http_method(cap.name || ""),
        path: "/api/v1/#{infer_resource(cap.subject || "")}",
        input_schema: %{},
        output_schema: %{type: "object"},
        version: "v1"
      }
    end)
  end

  defp extract_schemas_from_storage_models(storage_models) do
    Enum.map(storage_models, fn model ->
      %{
        name: Macro.camelize(model.entity || "Entity"),
        fields: model.fields || [],
        version: "v1"
      }
    end)
  end

  defp infer_events_from_workflows(workflows) do
    Enum.flat_map(workflows, fn workflow ->
      if workflow.steps && length(workflow.steps) > 1 do
        [%{
          topic: "#{workflow.name || "event"}.completed",
          schema: %{type: "object"},
          delivery_guarantee: :at_least_once,
          consumers: [],
          partitioning_strategy: :random
        }]
      else
        []
      end
    end)
  end

  defp infer_http_method(name) do
    name_lower = String.downcase(name)

    cond do
      String.contains?(name_lower, ["create", "add", "new"]) -> :post
      String.contains?(name_lower, ["update", "modify", "change"]) -> :put
      String.contains?(name_lower, ["delete", "remove"]) -> :delete
      true -> :get
    end
  end

  defp infer_resource(subject) do
    subject
    |> String.downcase()
    |> String.replace("service", "")
    |> String.trim()
  end
end
