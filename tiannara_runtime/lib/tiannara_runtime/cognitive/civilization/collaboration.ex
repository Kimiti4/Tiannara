defmodule TiannaraRuntime.Cognitive.Civilization.Collaboration do
  @schema_version 1
  @ontology_version 1
  @created_with_phase "19.1"

  defstruct [
    :id, :civilization_id, :source_institution, :target_institution,
    :domain_bridge, :programs, :status, :created_at
  ]

  @type t :: %__MODULE__{
    id: String.t() | nil,
    civilization_id: String.t() | nil,
    source_institution: String.t() | nil,
    target_institution: String.t() | nil,
    domain_bridge: String.t() | nil,
    programs: list(),
    status: String.t(),
    created_at: String.t()
  }

  @spec new(map()) :: {:ok, __MODULE__.t()} | {:error, String.t()}
  def new(fields \\ %{}) do
    s = %__MODULE__{
      id: Map.get(fields, :id),
      civilization_id: Map.get(fields, :civilization_id),
      source_institution: Map.get(fields, :source_institution),
      target_institution: Map.get(fields, :target_institution),
      domain_bridge: Map.get(fields, :domain_bridge),
      programs: Map.get(fields, :programs, []),
      status: Map.get(fields, :status, "pending"),
      created_at: Map.get(fields, :created_at, :os.system_time(:second) |> Integer.to_string())
    }
    with {:ok, s} <- validate(s) do
      {:ok, ensure_id(s)}
    end
  end

  @spec validate(__MODULE__.t()) :: {:ok, __MODULE__.t()} | {:error, String.t()}
  def validate(%__MODULE__{} = s), do: {:ok, s}
  def validate(_), do: {:error, "invalid Collaboration"}

  @spec generate_id(__MODULE__.t()) :: String.t()
  def generate_id(%__MODULE__{source_institution: src, target_institution: tgt} = s) do
    raw = (src || "") <> (tgt || "") <> inspect(Map.drop(Map.from_struct(s), [:__struct__, :id]))
    "col_" <> (:crypto.hash(:sha256, raw) |> Base.encode16(case: :lower))
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
