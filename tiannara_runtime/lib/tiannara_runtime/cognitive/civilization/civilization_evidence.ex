defmodule TiannaraRuntime.Cognitive.Civilization.CivilizationEvidence do
  @schema_version 1
  @ontology_version 1
  @created_with_phase "19.1"

  defstruct [
    :id, :civilization_id, :subsystem, :stage,
    :input_hash, :output_hash
  ]

  @type t :: %__MODULE__{
    id: String.t() | nil,
    civilization_id: String.t() | nil,
    subsystem: String.t() | nil,
    stage: String.t() | nil,
    input_hash: String.t() | nil,
    output_hash: String.t() | nil
  }

  @spec new(map()) :: {:ok, __MODULE__.t()} | {:error, String.t()}
  def new(fields \\ %{}) do
    s = %__MODULE__{
      id: Map.get(fields, :id),
      civilization_id: Map.get(fields, :civilization_id),
      subsystem: Map.get(fields, :subsystem),
      stage: Map.get(fields, :stage),
      input_hash: Map.get(fields, :input_hash),
      output_hash: Map.get(fields, :output_hash)
    }
    with {:ok, s} <- validate(s) do
      {:ok, ensure_id(s)}
    end
  end

  @spec validate(__MODULE__.t()) :: {:ok, __MODULE__.t()} | {:error, String.t()}
  def validate(%__MODULE__{} = s), do: {:ok, s}
  def validate(_), do: {:error, "invalid CivilizationEvidence"}

  @spec generate_id(__MODULE__.t()) :: String.t()
  def generate_id(%__MODULE__{civilization_id: civ_id, subsystem: sub, stage: stg} = s) do
    raw = (civ_id || "") <> (sub || "") <> (stg || "") <> inspect(Map.drop(Map.from_struct(s), [:__struct__, :id]))
    "cev_" <> (:crypto.hash(:sha256, raw) |> Base.encode16(case: :lower))
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
