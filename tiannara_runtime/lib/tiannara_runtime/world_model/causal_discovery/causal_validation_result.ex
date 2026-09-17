defmodule TiannaraRuntime.CausalDiscovery.CausalValidationResult do
  @moduledoc """
  Phase 17.3 — CausalValidationResult: combined result of all validation checks.
  Content-addressed ID prefix: vr_
  """
  @enforce_keys [:graph_fingerprint, :checks]
  defstruct [:validation_id, :graph_fingerprint, :checks, :overall, :created_at]

  @type overall :: :pass | :fail | :inconclusive

  @type t :: %__MODULE__{
    validation_id: String.t(),
    graph_fingerprint: String.t(),
    checks: [TiannaraRuntime.CausalDiscovery.ValidationCheck.t()],
    overall: overall(),
    created_at: String.t()
  }

  @spec new(keyword()) :: {:ok, t()} | {:error, String.t()}
  def new(opts \\ []) do
    now = DateTime.utc_now() |> DateTime.to_iso8601()
    vr = %__MODULE__{
      validation_id: Keyword.get(opts, :validation_id),
      graph_fingerprint: Keyword.get(opts, :graph_fingerprint),
      checks: Keyword.get(opts, :checks, []),
      overall: Keyword.get(opts, :overall, :inconclusive),
      created_at: Keyword.get(opts, :created_at, now)
    }
    with {:ok, vr} <- validate(vr),
         do: {:ok, ensure_id(vr)}
  end

  @spec validate(t()) :: {:ok, t()} | {:error, String.t()}
  def validate(%__MODULE__{graph_fingerprint: gf}) when is_nil(gf) or gf == "",
    do: {:error, "CausalValidationResult graph_fingerprint must not be empty"}
  def validate(%__MODULE__{checks: c}) when not is_list(c),
    do: {:error, "CausalValidationResult checks must be a list"}
  def validate(%__MODULE__{overall: o}) when o not in ~w(pass fail inconclusive)a,
    do: {:error, "CausalValidationResult overall must be :pass, :fail, or :inconclusive"}
  def validate(%__MODULE__{} = vr), do: {:ok, vr}
  def validate(_), do: {:error, "invalid CausalValidationResult"}

  @spec compute_id(t()) :: String.t()
  def compute_id(%__MODULE__{} = vr) do
    check_fps = vr.checks |> Enum.map(&TiannaraRuntime.CausalDiscovery.ValidationCheck.compute_fingerprint/1) |> Enum.sort() |> Enum.join("|")
    raw = vr.graph_fingerprint <> check_fps
    "vr_" <> (:crypto.hash(:sha256, raw) |> Base.encode16(case: :lower))
  end

  defp ensure_id(%__MODULE__{validation_id: nil} = vr), do: %{vr | validation_id: compute_id(vr)}
  defp ensure_id(%__MODULE__{} = vr), do: vr
end
