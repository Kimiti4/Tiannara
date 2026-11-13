defmodule Tiannara.Forecasting.Integrity do
  @moduledoc """
  Canonical integrity primitives for the forecasting lifecycle.

  Every durable artefact in the lifecycle — a forecast record, an observation,
  a verification result, a score — carries a digest over a **canonical**
  representation, so that two parties independently compute the same value and
  a tampered artefact is detectable.

  ## What a digest does and does not establish

  A digest establishes **integrity**: that the bytes are the bytes that were
  recorded. It does **not** establish **authenticity**: that the writer was
  the party it claims to be. Anyone with write access to the storage can
  recompute a digest over altered content.

  Where authenticity is required, the record must be covered by an
  authenticated mechanism — a signature under a key whose ownership and
  verification rules are explicit. This module provides only integrity, and
  the assurance level of any result derived from it must say so.
  """

  @algorithm "sha256"
  @domain "tiannara.forecasting.v1"

  @doc "The digest algorithm identifier recorded with every digest."
  @spec algorithm() :: String.t()
  def algorithm, do: @algorithm

  @doc "The canonicalisation domain. A change here invalidates stored digests."
  @spec domain() :: String.t()
  def domain, do: @domain

  @doc """
  Computes the digest of a term under the canonical representation.

  The canonical form is a versioned tuple, so that a future change to the
  domain or the term layout cannot silently collide with an existing digest.
  """
  @spec digest(term()) :: binary()
  def digest(term) do
    :crypto.hash(:sha256, canonical(term))
  end

  @doc "The canonical byte representation a digest is computed over."
  @spec canonical(term()) :: binary()
  def canonical(term) do
    :erlang.term_to_binary({@domain, term})
  end

  @doc "A hex digest, for human-readable reporting."
  @spec hex_digest(term()) :: String.t()
  def hex_digest(term) do
    digest(term) |> Base.encode16(case: :lower)
  end

  @doc """
  Verifies that a term still matches a recorded digest.

  Comparison is constant-time in the sense that it does not short-circuit on
  the first differing byte.
  """
  @spec verify(term(), binary() | nil) :: boolean()
  def verify(_term, nil), do: false

  def verify(term, expected) when is_binary(expected) do
    actual = digest(term)
    byte_size(actual) == byte_size(expected) and crypto_equal?(actual, expected)
  end

  defp crypto_equal?(a, b) do
    :crypto.exor(a, b) |> :binary.bin_to_list() |> Enum.sum() == 0
  end
end
