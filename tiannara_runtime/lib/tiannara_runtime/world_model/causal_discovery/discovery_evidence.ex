defmodule TiannaraRuntime.CausalDiscovery.DiscoveryEvidence do
  @moduledoc """
  Phase 17.3 — DiscoveryEvidence: evidence root tracking for a discovery pipeline stage.
  Content-addressed ID prefix: de_
  """
  @enforce_keys [:stage]
  defstruct [:discovery_id, :stage, :input_roots, :output_root, :config, :created_at]

  @type stage_type ::
    :independence | :skeleton | :orientation | :scoring |
    :latent | :validation | :intervention

  @type t :: %__MODULE__{
    discovery_id: String.t(),
    stage: stage_type(),
    input_roots: [String.t()],
    output_root: String.t(),
    config: map(),
    created_at: String.t()
  }

  @spec new(keyword()) :: {:ok, t()} | {:error, String.t()}
  def new(opts \\ []) do
    now = DateTime.utc_now() |> DateTime.to_iso8601()
    d = %__MODULE__{
      discovery_id: Keyword.get(opts, :discovery_id),
      stage: Keyword.get(opts, :stage),
      input_roots: Keyword.get(opts, :input_roots, []),
      output_root: Keyword.get(opts, :output_root),
      config: Keyword.get(opts, :config, %{}),
      created_at: Keyword.get(opts, :created_at, now)
    }
    with {:ok, d} <- validate(d),
         do: {:ok, ensure_id(d)}
  end

  @spec validate(t()) :: {:ok, t()} | {:error, String.t()}
  def validate(%__MODULE__{stage: s}) when s not in ~w(independence skeleton orientation scoring latent validation intervention)a,
    do: {:error, "DiscoveryEvidence stage must be a valid pipeline stage atom"}
  def validate(%__MODULE__{output_root: r}) when r != nil and (not is_binary(r) or r == ""),
    do: {:error, "DiscoveryEvidence output_root must be a valid string when provided"}
  def validate(%__MODULE__{} = d), do: {:ok, d}
  def validate(_), do: {:error, "invalid DiscoveryEvidence"}

  @spec canonicalize(t()) :: map()
  def canonicalize(%__MODULE__{} = d) do
    Map.from_struct(d)
    |> Map.delete(:__struct__)
    |> Enum.map(fn {k, v} -> {to_string(k), canonical_value(v)} end)
    |> Enum.sort_by(fn {k, _} -> k end)
    |> Enum.into(%{})
  end

  defp canonical_value(v) when is_map(v), do: v |> Enum.sort_by(fn {k, _} -> to_string(k) end) |> Enum.into(%{})
  defp canonical_value(v), do: v

  @spec compute_id(t()) :: String.t()
  def compute_id(%__MODULE__{} = d) do
    raw = Atom.to_string(d.stage) <>
          (d.input_roots |> Enum.sort() |> Enum.join("|")) <>
          (d.output_root || "")
    "de_" <> (:crypto.hash(:sha256, raw) |> Base.encode16(case: :lower))
  end

  defp ensure_id(%__MODULE__{discovery_id: nil} = d), do: %{d | discovery_id: compute_id(d)}
  defp ensure_id(%__MODULE__{} = d), do: d
end
