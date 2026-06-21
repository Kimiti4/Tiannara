defmodule TiannaraOS.ToolGenome do
  @moduledoc """
  Represents an evolvable specification for a system capability in TiannaraOS.
  """

  @derive Jason.Encoder
  defstruct [
    :id,                  # atom() - unique identifier
    :capability,          # atom() - capability identifier: e.g., :find_insecure_dependency
    :capability_type,     # atom() - categorizes the capability: e.g., :repository_analysis
    :execution_backend,   # atom() - e.g., :interpreter, :fastapi, :docker, :workflow
    :execution_spec,      # map() - parameters/rules guiding execution
    :security_profile,    # map() - safety parameters (e.g. %{read_sandbox: true})
    parent_genomes: [],   # list(atom()) - parent genome IDs
    provenance: [],       # list(String.t()) - lineage history
    version: "0.1.0",     # String.t() - version tag
    fitness: 0.0          # float() - evolutionary rating (0.0 to 1.0)
  ]

  @type t :: %__MODULE__{
    id: atom(),
    capability: atom(),
    capability_type: atom(),
    execution_backend: :interpreter | :fastapi | :docker | :workflow,
    execution_spec: map(),
    security_profile: map(),
    parent_genomes: [atom()],
    provenance: [String.t()],
    version: String.t(),
    fitness: float()
  }
end
