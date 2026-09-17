defmodule TiannaraRuntime.Cognitive.Civilization.Civilization do
  @schema_version 1
  @ontology_version 1
  @created_with_phase "19.1"

  defstruct [
    :id, :name, :institutions, :programs, :portfolios,
    :economy, :collaborations, :knowledge_graph, :status, :created_at
  ]

  @type t :: %__MODULE__{
    id: String.t() | nil,
    name: String.t(),
    institutions: list(),
    programs: list(),
    portfolios: list(),
    economy: map(),
    collaborations: list(),
    knowledge_graph: map(),
    status: String.t(),
    created_at: String.t()
  }

  @spec new(map()) :: {:ok, __MODULE__.t()} | {:error, String.t()}
  def new(fields \\ %{}) do
    s = %__MODULE__{
      id: Map.get(fields, :id),
      name: Map.get(fields, :name, "Unnamed Civilization"),
      institutions: Map.get(fields, :institutions, []),
      programs: Map.get(fields, :programs, []),
      portfolios: Map.get(fields, :portfolios, []),
      economy: Map.get(fields, :economy, %{}),
      collaborations: Map.get(fields, :collaborations, []),
      knowledge_graph: Map.get(fields, :knowledge_graph, %{}),
      status: Map.get(fields, :status, "nascent"),
      created_at: Map.get(fields, :created_at, :os.system_time(:second) |> Integer.to_string())
    }
    with {:ok, s} <- validate(s) do
      {:ok, ensure_id(s)}
    end
  end

  @spec validate(__MODULE__.t()) :: {:ok, __MODULE__.t()} | {:error, String.t()}
  def validate(%__MODULE__{} = s), do: {:ok, s}
  def validate(_), do: {:error, "invalid Civilization"}

  @spec generate_id(__MODULE__.t()) :: String.t()
  def generate_id(%__MODULE__{name: name} = s) do
    raw = name <> inspect(Map.drop(Map.from_struct(s), [:__struct__, :id]))
    "civ_" <> (:crypto.hash(:sha256, raw) |> Base.encode16(case: :lower))
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
