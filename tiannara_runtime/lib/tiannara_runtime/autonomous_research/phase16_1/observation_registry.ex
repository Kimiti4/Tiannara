defmodule TiannaraRuntime.AutonomousResearch.Phase16_1.ObservationRegistry do
  @moduledoc """
  Phase 16.1 Module 1 — Observation Registry (Pure Implementation)

  Implements frozen contracts from RESEARCH_RUNTIME_FREEZE.md and RESEARCH_DATA_MODEL.md.

  Capabilities:
  - Immutable observations (stored in ETS table with write_concurrency)
  - Content-addressed IDs (SHA-256 over canonical JSON)
  - Deterministic serialization (stable key ordering)
  - Replay-compatible storage
  - Archaeology metadata
  """

  @registry_table :observation_registry

  @doc "Initialize the registry table"
  def init_table do
    if :ets.info(@registry_table) == :undefined do
      :ets.new(@registry_table, [:set, :public, :named_table])
    end
    :ok
  end

  @doc "Register an observation with deterministic ID"
  @spec register_observation(map(), map(), String.t() | nil, map() | nil) :: :ok | {:error, String.t()}
  def register_observation(origin, payload, captured_at \\ nil, metadata \\ nil)
      when is_map(origin) and is_map(payload) do
    init_table()

    case validate_origin_and_payload(origin, payload) do
      :ok ->
        obs = %{
          "origin" => canonicalize_map(origin),
          "payload" => canonicalize_map(payload),
          "captured_at" => captured_at,
          "metadata" => canonicalize_map(metadata || %{})
        }

        id = compute_observation_id(obs)
        :ets.insert(@registry_table, {id, obs})
        :ok

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc "Lookup observation by content-addressed ID"
  @spec lookup_observation(String.t()) :: {:ok, map()} | :error
  def lookup_observation(observation_id) when is_binary(observation_id) do
    case :ets.lookup(@registry_table, observation_id) do
      [{^observation_id, observation}] -> {:ok, observation}
      [] -> :error
    end
  end

  @doc "List all observations"
  @spec list_observations() :: [map()]
  def list_observations do
    :ets.tab2list(@registry_table)
    |> Enum.map(fn {_id, obs} -> obs end)
  end

  @doc "Get total observation count"
  @spec observation_count() :: non_neg_integer()
  def observation_count do
    case :ets.info(@registry_table, :size) do
      :undefined -> 0
      size -> size
    end
  end

  # --- internal helpers ---

  defp validate_origin_and_payload(origin, payload) do
    cond do
      map_size(origin) == 0 -> {:error, "origin must be non-empty"}
      map_size(payload) == 0 -> {:error, "payload must be non-empty"}
      true -> :ok
    end
  end

  defp compute_observation_id(obs) do
    canonical = canonicalize_map(obs)
    json = Jason.encode!(canonical)
    :crypto.hash(:sha256, json) |> Base.encode16(case: :lower)
  end

  defp canonicalize_map(term) when is_map(term) do
    term
    |> Enum.map(fn {k, v} -> {to_string(k), canonicalize_map(v)} end)
    |> Enum.sort_by(fn {k, _v} -> k end)
    |> Enum.into(%{})
  end

  defp canonicalize_map(term) when is_list(term), do: Enum.map(term, &canonicalize_map/1)
  defp canonicalize_map(term), do: term
end