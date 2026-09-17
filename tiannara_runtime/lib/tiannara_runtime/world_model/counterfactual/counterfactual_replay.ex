defmodule TiannaraRuntime.WorldModel.Counterfactual.CounterfactualReplay do
  @moduledoc """
  Phase 17.5.8 — CounterfactualReplay: computes deterministic fingerprints
  and verifies counterfactual replay determinism. Integrates with the
  Mathematics Substrate for formal verification.
  """
  alias TiannaraRuntime.WorldModel.Counterfactual.CounterfactualWorld

  @spec fingerprint(CounterfactualWorld.t()) :: String.t()
  def fingerprint(%CounterfactualWorld{} = cf) do
    excluded = [:counterfactual_id, :archaeology_root, :created_at, :metadata, :replay_fingerprint]

    canonical =
      cf
      |> Map.from_struct()
      |> Map.drop(excluded)
      |> Enum.map(fn {k, v} -> {to_string(k), canonicalize_value(v)} end)
      |> Enum.sort()
      |> Enum.into(%{})
      |> Jason.encode!()

    "fp_" <> (:crypto.hash(:sha256, canonical) |> Base.encode16(case: :lower))
  end

  @spec verify(CounterfactualWorld.t()) :: {:ok, %{verified: boolean(), mismatches: [String.t()]}}
  def verify(%CounterfactualWorld{replay_fingerprint: stored_fp} = cf) do
    computed_fp = fingerprint(cf)

    if stored_fp == computed_fp do
      {:ok, %{verified: true, mismatches: []}}
    else
      {:ok, %{verified: false, mismatches: ["fingerprint_mismatch"], stored: stored_fp, computed: computed_fp}}
    end
  end

  @spec replay(CounterfactualWorld.t()) :: {:ok, CounterfactualWorld.t()} | {:error, String.t()}
  def replay(%CounterfactualWorld{} = cf) do
    with {:ok, %{verified: true}} <- verify(cf) do
      {:ok, cf}
    else
      {:ok, %{verified: false}} -> {:error, "Replay verification failed: fingerprint mismatch"}
      error -> error
    end
  end

  defp canonicalize_value(v) when is_map(v), do: canonicalize_map(v)
  defp canonicalize_value(v) when is_list(v), do: Enum.map(v, &canonicalize_value/1)
  defp canonicalize_value(v) when is_atom(v), do: Atom.to_string(v)
  defp canonicalize_value(v), do: v

  defp canonicalize_map(map) do
    map
    |> Map.drop([:__struct__])
    |> Enum.map(fn {k, v} -> {to_string(k), canonicalize_value(v)} end)
    |> Enum.into(%{})
  end
end
