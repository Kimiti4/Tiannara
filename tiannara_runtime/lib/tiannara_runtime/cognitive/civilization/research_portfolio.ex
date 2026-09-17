defmodule TiannaraRuntime.Cognitive.Civilization.ResearchPortfolio do
  @schema_version 1
  @ontology_version 1
  @created_with_phase "19.1"

  defstruct [
    :id, :civilization_id, :programs, :novelty_score,
    :uncertainty_score, :maturity_score, :productivity,
    :expected_impact, :collaboration_density
  ]

  @type t :: %__MODULE__{
    id: String.t() | nil,
    civilization_id: String.t() | nil,
    programs: list(),
    novelty_score: float(),
    uncertainty_score: float(),
    maturity_score: float(),
    productivity: float(),
    expected_impact: float(),
    collaboration_density: float()
  }

  @spec new(map()) :: {:ok, __MODULE__.t()} | {:error, String.t()}
  def new(fields \\ %{}) do
    s = %__MODULE__{
      id: Map.get(fields, :id),
      civilization_id: Map.get(fields, :civilization_id),
      programs: Map.get(fields, :programs, []),
      novelty_score: Map.get(fields, :novelty_score, 0.0),
      uncertainty_score: Map.get(fields, :uncertainty_score, 0.0),
      maturity_score: Map.get(fields, :maturity_score, 0.0),
      productivity: Map.get(fields, :productivity, 0.0),
      expected_impact: Map.get(fields, :expected_impact, 0.0),
      collaboration_density: Map.get(fields, :collaboration_density, 0.0)
    }
    with {:ok, s} <- validate(s) do
      {:ok, ensure_id(s)}
    end
  end

  @spec validate(__MODULE__.t()) :: {:ok, __MODULE__.t()} | {:error, String.t()}
  def validate(%__MODULE__{} = s), do: {:ok, s}
  def validate(_), do: {:error, "invalid ResearchPortfolio"}

  @spec generate_id(__MODULE__.t()) :: String.t()
  def generate_id(%__MODULE__{civilization_id: civ_id} = s) do
    raw = (civ_id || "") <> inspect(Map.drop(Map.from_struct(s), [:__struct__, :id]))
    "rpf_" <> (:crypto.hash(:sha256, raw) |> Base.encode16(case: :lower))
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
