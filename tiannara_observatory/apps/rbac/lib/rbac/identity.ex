defmodule Rbac.Identity do
  @moduledoc """
  Constitutional Identity Service.

  Identity is: identity → credential → token → capabilities → trust_level → revocation → lineage.

  Supports:
    - Human operators (user accounts)
    - Service accounts (automated agents)
    - AI workers (runtime-authenticated)
    - Emergency recovery (break-glass)
  """

  defstruct [
    :id,
    :type,
    :name,
    :roles,
    :capabilities,
    :trust_level,
    :credentials,
    :revoked?,
    :lineage,
    :metadata
  ]

  @type t :: %__MODULE__{
          id: String.t(),
          type: :human | :service | :ai_worker | :emergency | :guest,
          name: String.t(),
          roles: [atom()],
          capabilities: [String.t()],
          trust_level: 1..5,
          credentials: map(),
          revoked?: boolean(),
          lineage: [String.t()],
          metadata: map()
        }

  @doc "Create a new identity."
  def new(type, name, opts \\ []) do
    %__MODULE__{
      id: Ecto.UUID.generate(),
      type: type,
      name: name,
      roles: opts[:roles] || [],
      capabilities: opts[:capabilities] || resolve_capabilities(opts[:roles] || []),
      trust_level: opts[:trust_level] || trust_level_for(type),
      credentials: opts[:credentials] || %{},
      revoked?: false,
      lineage: [Ecto.UUID.generate()],
      metadata: opts[:metadata] || %{}
    }
  end

  @doc "Resolve capabilities from roles."
  def resolve_capabilities(roles) do
    Enum.flat_map(roles, fn role ->
      case role do
        :root ->
          Rbac.Capability.all()

        :administrator ->
          ~w(metrics.* events.* replay.* configuration.* admin.* audit.* runtime.*)

        :scientist ->
          ~w(metrics.read events.read science.* theory.* replay.read)

        :engineer ->
          ~w(metrics.read events.read engineering.* runtime.health.read configuration.read)

        :auditor ->
          ~w(metrics.read events.read audit.* replay.* certification.*)

        :observer ->
          ~w(metrics.read events.read)

        :guest ->
          ~w(metrics.read)

        _ ->
          []
      end
    end)
  end

  defp trust_level_for(:root), do: 5
  defp trust_level_for(:human), do: 4
  defp trust_level_for(:service), do: 3
  defp trust_level_for(:ai_worker), do: 2
  defp trust_level_for(:guest), do: 1
  defp trust_level_for(:emergency), do: 5
  defp trust_level_for(_), do: 1

  @doc "Dev seed identities."
  def seed do
    %{
      admin: new(:human, "Admin", roles: [:administrator], capabilities: Rbac.Capability.all()),
      scientist: new(:human, "Scientist", roles: [:scientist]),
      engineer: new(:human, "Engineer", roles: [:engineer]),
      auditor: new(:human, "Auditor", roles: [:auditor]),
      observer: new(:human, "Observer", roles: [:observer]),
      system:
        new(:service, "Telemetry Gateway",
          roles: [:service],
          capabilities: ~w(events.write metrics.write)
        ),
      ai_worker:
        new(:ai_worker, "Discovery Agent Alpha",
          roles: [:ai_worker],
          capabilities:
            ~w(science.discoveries.read science.experiments.start metrics.read replay.execute)
        )
    }
  end
end
