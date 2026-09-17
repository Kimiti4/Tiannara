defmodule TiannaraRuntime.Cognitive.Civilization.CivilizationMetrics do
  @schema_version 1
  @ontology_version 1
  @created_with_phase "19.1"

  @type t :: %__MODULE__{}

  defstruct [
    :id, :civilization_id, :institution_count, :program_count,
    :portfolio_count, :collaboration_count, :total_discoveries,
    :total_capital, :avg_maturity, :avg_impact
  ]

  @spec new(map()) :: {:ok, __MODULE__.t()} | {:error, String.t()}
  def new(fields \\ %{}) do
    s = %__MODULE__{
      id: Map.get(fields, :id),
      civilization_id: Map.get(fields, :civilization_id),
      institution_count: Map.get(fields, :institution_count, 0),
      program_count: Map.get(fields, :program_count, 0),
      portfolio_count: Map.get(fields, :portfolio_count, 0),
      collaboration_count: Map.get(fields, :collaboration_count, 0),
      total_discoveries: Map.get(fields, :total_discoveries, 0),
      total_capital: Map.get(fields, :total_capital, 0),
      avg_maturity: Map.get(fields, :avg_maturity, 0.0),
      avg_impact: Map.get(fields, :avg_impact, 0.0)
    }
    with {:ok, s} <- validate(s) do
      {:ok, ensure_id(s)}
    end
  end

  @spec validate(__MODULE__.t()) :: {:ok, __MODULE__.t()} | {:error, String.t()}
  def validate(%__MODULE__{} = s), do: {:ok, s}
  def validate(_), do: {:error, "invalid CivilizationMetrics"}

  @spec generate_id(__MODULE__.t()) :: String.t()
  def generate_id(%__MODULE__{civilization_id: civ_id} = s) do
    raw = (civ_id || "") <> inspect(Map.drop(Map.from_struct(s), [:__struct__, :id]))
    "cm_" <> (:crypto.hash(:sha256, raw) |> Base.encode16(case: :lower))
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
