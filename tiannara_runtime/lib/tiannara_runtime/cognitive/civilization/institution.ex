defmodule TiannaraRuntime.Cognitive.Civilization.Institution do
  @schema_version 1
  @ontology_version 1
  @created_with_phase "19.1"

  defstruct [
    :id, :civilization_id, :name, :domain, :programs,
    :resources, :metrics, :status
  ]

  @type t :: %__MODULE__{
    id: String.t() | nil,
    civilization_id: String.t() | nil,
    name: String.t(),
    domain: String.t(),
    programs: list(),
    resources: map(),
    metrics: map(),
    status: String.t()
  }

  @spec new(map()) :: {:ok, __MODULE__.t()} | {:error, String.t()}
  def new(fields \\ %{}) do
    s = %__MODULE__{
      id: Map.get(fields, :id),
      civilization_id: Map.get(fields, :civilization_id),
      name: Map.get(fields, :name, "Unnamed Institution"),
      domain: Map.get(fields, :domain, "general"),
      programs: Map.get(fields, :programs, []),
      resources: Map.get(fields, :resources, %{}),
      metrics: Map.get(fields, :metrics, %{}),
      status: Map.get(fields, :status, "active")
    }
    with {:ok, s} <- validate(s) do
      {:ok, ensure_id(s)}
    end
  end

  @spec validate(__MODULE__.t()) :: {:ok, __MODULE__.t()} | {:error, String.t()}
  def validate(%__MODULE__{} = s), do: {:ok, s}
  def validate(_), do: {:error, "invalid Institution"}

  @spec generate_id(__MODULE__.t()) :: String.t()
  def generate_id(%__MODULE__{name: name, civilization_id: civ_id} = s) do
    raw = name <> (civ_id || "") <> inspect(Map.drop(Map.from_struct(s), [:__struct__, :id]))
    "inst_" <> (:crypto.hash(:sha256, raw) |> Base.encode16(case: :lower))
  end

  @spec compute_fingerprint(__MODULE__.t()) :: String.t()
  def compute_fingerprint(%__MODULE__{} = s) do
    raw =
      s
      |> Map.from_struct()
      |> Map.drop([:__struct__, :id])
      |> :erlang.term_to_binary()
    :crypto.hash(:sha256, raw) |> Base.encode16(case: :lower)
  end

  defp ensure_id(%__MODULE__{id: nil} = s), do: %{s | id: generate_id(s)}
  defp ensure_id(%__MODULE__{} = s), do: s
end
