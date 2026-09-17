defmodule TiannaraRuntime.Cognitive.Civilization.ResearchProgram do
  @schema_version 1
  @ontology_version 1
  @created_with_phase "19.1"

  defstruct [
    :id, :institution_id, :name, :domain, :status, :portfolio_id,
    :discoveries, :capital_invested, :expected_impact, :maturity
  ]

  @type t :: %__MODULE__{
    id: String.t() | nil,
    institution_id: String.t() | nil,
    name: String.t(),
    domain: String.t(),
    status: String.t(),
    portfolio_id: String.t() | nil,
    discoveries: list(),
    capital_invested: integer(),
    expected_impact: float(),
    maturity: float()
  }

  @spec new(map()) :: {:ok, __MODULE__.t()} | {:error, String.t()}
  def new(fields \\ %{}) do
    s = %__MODULE__{
      id: Map.get(fields, :id),
      institution_id: Map.get(fields, :institution_id),
      name: Map.get(fields, :name, "Unnamed Program"),
      domain: Map.get(fields, :domain, "general"),
      status: Map.get(fields, :status, "proposed"),
      portfolio_id: Map.get(fields, :portfolio_id),
      discoveries: Map.get(fields, :discoveries, []),
      capital_invested: Map.get(fields, :capital_invested, 0),
      expected_impact: Map.get(fields, :expected_impact, 0.0),
      maturity: Map.get(fields, :maturity, 0.0)
    }
    with {:ok, s} <- validate(s) do
      {:ok, ensure_id(s)}
    end
  end

  @spec validate(__MODULE__.t()) :: {:ok, __MODULE__.t()} | {:error, String.t()}
  def validate(%__MODULE__{} = s), do: {:ok, s}
  def validate(_), do: {:error, "invalid ResearchProgram"}

  @spec generate_id(__MODULE__.t()) :: String.t()
  def generate_id(%__MODULE__{name: name, institution_id: inst_id} = s) do
    raw = name <> (inst_id || "") <> inspect(Map.drop(Map.from_struct(s), [:__struct__, :id]))
    "rp_" <> (:crypto.hash(:sha256, raw) |> Base.encode16(case: :lower))
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
