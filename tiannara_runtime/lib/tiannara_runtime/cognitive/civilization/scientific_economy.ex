defmodule TiannaraRuntime.Cognitive.Civilization.ScientificEconomy do
  @schema_version 1
  @ontology_version 1
  @created_with_phase "19.1"

  @type t :: %__MODULE__{}

  defstruct [
    :id, :civilization_id, :capital_ledger, :total_capital,
    :discoveries_count, :proofs_count, :datasets_count, :software_count
  ]

  @spec new(map()) :: {:ok, __MODULE__.t()} | {:error, String.t()}
  def new(fields \\ %{}) do
    s = %__MODULE__{
      id: Map.get(fields, :id),
      civilization_id: Map.get(fields, :civilization_id),
      capital_ledger: Map.get(fields, :capital_ledger, []),
      total_capital: Map.get(fields, :total_capital, 0),
      discoveries_count: Map.get(fields, :discoveries_count, 0),
      proofs_count: Map.get(fields, :proofs_count, 0),
      datasets_count: Map.get(fields, :datasets_count, 0),
      software_count: Map.get(fields, :software_count, 0)
    }
    with {:ok, s} <- validate(s) do
      {:ok, ensure_id(s)}
    end
  end

  @spec validate(__MODULE__.t()) :: {:ok, __MODULE__.t()} | {:error, String.t()}
  def validate(%__MODULE__{} = s), do: {:ok, s}
  def validate(_), do: {:error, "invalid ScientificEconomy"}

  @spec generate_id(__MODULE__.t()) :: String.t()
  def generate_id(%__MODULE__{civilization_id: civ_id} = s) do
    raw = (civ_id || "") <> inspect(Map.drop(Map.from_struct(s), [:__struct__, :id]))
    "se_" <> (:crypto.hash(:sha256, raw) |> Base.encode16(case: :lower))
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
