defmodule TiannaraRuntime.Cognitive.Civilization.CivilizationArchaeology do
  @schema_version 1
  @ontology_version 1
  @created_with_phase "19.1"

  @type t :: %__MODULE__{}

  defstruct [
    :id, :civilization_id, :origin, :civilization_narrative,
    :institution_summaries, :economic_history, :collaboration_log
  ]

  @spec new(map()) :: {:ok, __MODULE__.t()} | {:error, String.t()}
  def new(fields \\ %{}) do
    s = %__MODULE__{
      id: Map.get(fields, :id),
      civilization_id: Map.get(fields, :civilization_id),
      origin: Map.get(fields, :origin),
      civilization_narrative: Map.get(fields, :civilization_narrative),
      institution_summaries: Map.get(fields, :institution_summaries, []),
      economic_history: Map.get(fields, :economic_history, []),
      collaboration_log: Map.get(fields, :collaboration_log, [])
    }
    with {:ok, s} <- validate(s) do
      {:ok, ensure_id(s)}
    end
  end

  @spec validate(__MODULE__.t()) :: {:ok, __MODULE__.t()} | {:error, String.t()}
  def validate(%__MODULE__{} = s), do: {:ok, s}
  def validate(_), do: {:error, "invalid CivilizationArchaeology"}

  @spec generate_id(__MODULE__.t()) :: String.t()
  def generate_id(%__MODULE__{civilization_id: civ_id, origin: origin} = s) do
    raw = (civ_id || "") <> (origin || "") <> inspect(Map.drop(Map.from_struct(s), [:__struct__, :id]))
    "ca_" <> (:crypto.hash(:sha256, raw) |> Base.encode16(case: :lower))
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
