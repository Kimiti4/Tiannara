defmodule TiannaraOS.Provenance.Canon do
  @moduledoc """
  Canonical serialization and hashing.

  LOAD-BEARING SPECIFICATION. Every identity, payload and envelope hash in the
  forward provenance system is a SHA-256 over the output of `canon/1` (or
  `hash_bytes/1` for raw bytes). No other rendering is authoritative. This
  directly addresses the historical failure mode: certificates whose stored
  hash could not be reproduced because no canonical serialization was defined
  (see TIA_PROVENANCE_ARCHITECTURE_RECONNAISSANCE artifact: `governance/FINAL
  certificate hash semantics undefined`).

  Rules (see spec/canonicalization_spec.yaml for the normative copy):
    * objects: maps with binary keys, emitted in byte-lexicographic key order
    * arrays: lists in element order
    * strings: JSON-escaped, no trailing whitespace
    * integers: decimal
    * floats: shortest round-trip representation, always rendered with one or
      more digits on both sides of the decimal point (never `1.0` -> `1.0e0`)
    * nil -> `null`, true/false as JSON booleans
    * no whitespace except inside string literals
  """

  @doc "Canonical byte rendering of a JSON-compatible term."
  def canon(term), do: term |> to_json() |> IO.iodata_to_binary()

  defp to_json(nil), do: "null"
  defp to_json(:null), do: "null"
  defp to_json(true), do: "true"
  defp to_json(false), do: "false"
  defp to_json(i) when is_integer(i), do: Integer.to_string(i)

  defp to_json(f) when is_float(f) do
    # :short gives the shortest representation that round-trips.
    s = :erlang.float_to_binary(f, [:short])
    # Guarantee a fractional digit so `1.0` is distinct from integer `1`.
    if String.contains?(s, ".") or String.contains?(s, "e"),
      do: s,
      else: s <> ".0"
  end

  defp to_json(s) when is_binary(s) do
    # :json.encode/1 on OTP yields standards-compliant JSON string escaping.
    :json.encode(s)
  end

  defp to_json(l) when is_list(l) do
    ["[", Enum.map_intersperse(l, ",", &to_json/1), "]"]
  end

  defp to_json(t) when is_tuple(t) do
    to_json(Tuple.to_list(t))
  end

  defp to_json(m) when is_map(m) do
    pairs =
      m
      |> Enum.map(fn {k, v} -> {String.Chars.to_string(k), v} end)
      |> Enum.sort_by(fn {k, _} -> k end)

    ["{", Enum.map_intersperse(pairs, ",", fn {k, v} -> [esc_key(k), ":", to_json(v)] end), "}"]
  end

  defp to_json(other) do
    raise ArgumentError, "cannot canonically serialize: #{inspect(other)}"
  end

  defp esc_key(k) do
    # Keys are JSON strings; :json.encode renders escaping.
    :json.encode(k)
  end

  @doc "SHA-256 hex digest over canonical bytes of a term."
  def sha256(term) do
    :crypto.hash(:sha256, canon(term)) |> Base.encode16(case: :lower)
  end

  @doc "SHA-256 hex digest over raw bytes."
  def sha256_bytes(bytes) do
    :crypto.hash(:sha256, bytes) |> Base.encode16(case: :lower)
  end

  @doc "SHA-256 hex digest over canonical bytes; alias used by envelope maths."
  def psha256(term), do: sha256(term)
end