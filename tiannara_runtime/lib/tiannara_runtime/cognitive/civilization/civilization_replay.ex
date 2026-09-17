defmodule TiannaraRuntime.Cognitive.Civilization.CivilizationReplay do
  @schema_version 1
  @ontology_version 1
  @created_with_phase "19.1"

  @type t :: %__MODULE__{}

  defstruct [
    :id, :civilization_id, :civilization_root, :institution_root,
    :portfolio_root, :economy_root, :collaboration_root, :knowledge_root
  ]

  @spec new(map()) :: {:ok, __MODULE__.t()} | {:error, String.t()}
  def new(fields \\ %{}) do
    s = %__MODULE__{
      id: Map.get(fields, :id),
      civilization_id: Map.get(fields, :civilization_id),
      civilization_root: Map.get(fields, :civilization_root),
      institution_root: Map.get(fields, :institution_root),
      portfolio_root: Map.get(fields, :portfolio_root),
      economy_root: Map.get(fields, :economy_root),
      collaboration_root: Map.get(fields, :collaboration_root),
      knowledge_root: Map.get(fields, :knowledge_root)
    }
    with {:ok, s} <- validate(s) do
      {:ok, ensure_id(s)}
    end
  end

  @spec validate(__MODULE__.t()) :: {:ok, __MODULE__.t()} | {:error, String.t()}
  def validate(%__MODULE__{} = s), do: {:ok, s}
  def validate(_), do: {:error, "invalid CivilizationReplay"}

  @spec generate_id(__MODULE__.t()) :: String.t()
  def generate_id(%__MODULE__{civilization_id: civ_id, civilization_root: civ_root} = s) do
    raw = (civ_id || "") <> (civ_root || "") <> inspect(Map.drop(Map.from_struct(s), [:__struct__, :id]))
    "cr_" <> (:crypto.hash(:sha256, raw) |> Base.encode16(case: :lower))
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
