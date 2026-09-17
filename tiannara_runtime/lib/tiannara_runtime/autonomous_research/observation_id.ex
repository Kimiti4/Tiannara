defmodule TiannaraRuntime.AutonomousResearch.ObservationID do
  @moduledoc """
  Phase 16.1 — Autonomous Constitutional Research Runtime (Module 1)

  Content-addressed identifier for observations.

  Deterministic rule:
  - canonical JSON (stable key ordering)
  - SHA-256 over the canonical bytes
  - returned as lowercase hex

  This module is deliberately implementation-only and does not perform
  certification/validation/audit.
  """

  @type t :: String.t()

  @spec from_canonical_map(map()) :: t()
  def from_canonical_map(map) when is_map(map) do
    map
    |> canonicalize()
    |> json_canonical_bytes()
    |> sha256_hex()
  end

  @spec from_bytes(binary()) :: t()
  def from_bytes(bytes) when is_binary(bytes) do
    bytes |> sha256_hex()
  end

  # --- internal ---

  # Deterministic canonicalization:
  # - recursively sorts map keys
  # - normalizes lists as-is (caller controls ordering)
  defp canonicalize(term) when is_map(term) do
    term
    |> Enum.map(fn {k, v} -> {to_string(k), canonicalize(v)} end)
    |> Enum.sort_by(fn {k, _v} -> k end)
    |> Enum.into(%{})
  end

  defp canonicalize(term) when is_list(term) do
    Enum.map(term, &canonicalize/1)
  end

  defp canonicalize(term), do: term

  # Use :jason if available; fallback to Erlang term -> JSON via Jason only at runtime.
  defp json_canonical_bytes(canonical_map) do
    # :jason produces deterministic output for maps when keys are already ordered.
    # We canonicalized keys deterministically above.
    json = Jason.encode!(canonical_map)
    json |> to_string() |> then(& &1)
  end

  defp sha256_hex(bytes) do
    :crypto.hash(:sha256, bytes)
    |> Base.encode16(case: :lower)
  end
end
