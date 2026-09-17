defmodule TiannaraRuntime.CausalDiscovery.ValidationCheck do
  @moduledoc """
  Phase 17.3 — ValidationCheck: an individual check within a validation result.
  Content-addressed ID prefix: vc_
  """
  @enforce_keys [:check_name, :status]
  defstruct [:check_name, :status, :details, :fingerprint]

  @type status :: :pass | :fail | :skipped

  @type t :: %__MODULE__{
    check_name: String.t(),
    status: status(),
    details: String.t() | nil,
    fingerprint: String.t() | nil
  }

  @spec new(keyword()) :: {:ok, t()} | {:error, String.t()}
  def new(opts \\ []) do
    vc = %__MODULE__{
      check_name: Keyword.get(opts, :check_name),
      status: Keyword.get(opts, :status),
      details: Keyword.get(opts, :details),
      fingerprint: Keyword.get(opts, :fingerprint)
    }
    validate(vc)
  end

  @spec validate(t()) :: {:ok, t()} | {:error, String.t()}
  def validate(%__MODULE__{check_name: n}) when is_nil(n) or n == "",
    do: {:error, "ValidationCheck check_name must not be empty"}
  def validate(%__MODULE__{status: s}) when s not in ~w(pass fail skipped)a,
    do: {:error, "ValidationCheck status must be :pass, :fail, or :skipped"}
  def validate(%__MODULE__{} = vc), do: {:ok, vc}
  def validate(_), do: {:error, "invalid ValidationCheck"}

  @spec compute_fingerprint(t()) :: String.t()
  def compute_fingerprint(%__MODULE__{} = vc) do
    raw = vc.check_name <> Atom.to_string(vc.status) <> (vc.details || "")
    "vc_" <> (:crypto.hash(:sha256, raw) |> Base.encode16(case: :lower))
  end

  def canonicalize(%__MODULE__{} = vc) do
    Map.from_struct(vc)
    |> Map.delete(:__struct__)
    |> Enum.map(fn {k, v} -> {to_string(k), v} end)
    |> Enum.sort_by(fn {k, _} -> k end)
    |> Enum.into(%{})
  end
end
