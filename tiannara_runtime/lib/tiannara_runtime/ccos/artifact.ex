defmodule TiannaraRuntime.CCOS.Artifact do
  @moduledoc """
  Phase 18.2 shared artifact helpers for CCOS.

  These helpers are deterministic and content-addressed. They do not create
  timestamps, defaults, mock data, or hidden state.
  """

  alias TiannaraRuntime.Shared.Canonical

  @spec require_field(map(), atom()) :: {:ok, term()} | {:error, String.t()}
  def require_field(map, field) when is_map(map) and is_atom(field) do
    case Map.fetch(map, field) do
      {:ok, value} -> {:ok, value}
      :error -> fetch_string_key(map, field)
    end
  end

  @spec require_binary(map(), atom()) :: {:ok, String.t()} | {:error, String.t()}
  def require_binary(map, field) do
    with {:ok, value} <- require_field(map, field) do
      if is_binary(value) and value != "" do
        {:ok, value}
      else
        {:error, "#{field} must be a non-empty string"}
      end
    end
  end

  @spec require_list(map(), atom()) :: {:ok, list()} | {:error, String.t()}
  def require_list(map, field) do
    with {:ok, value} <- require_field(map, field) do
      if is_list(value) do
        {:ok, value}
      else
        {:error, "#{field} must be a list"}
      end
    end
  end

  @spec require_map(map(), atom()) :: {:ok, map()} | {:error, String.t()}
  def require_map(map, field) do
    with {:ok, value} <- require_field(map, field) do
      if is_map(value) do
        {:ok, value}
      else
        {:error, "#{field} must be a map"}
      end
    end
  end

  @spec content_id(String.t(), map()) :: String.t()
  def content_id(prefix, artifact) when is_binary(prefix) and is_map(artifact) do
    Canonical.generate_id(artifact, :artifact_id, prefix)
  end

  @spec fingerprint(map()) :: String.t()
  def fingerprint(artifact) when is_map(artifact) do
    content_id("ccosfp", artifact)
  end

  @spec sort_by_content_hash([map()]) :: [map()]
  def sort_by_content_hash(artifacts) when is_list(artifacts) do
    Enum.sort_by(artifacts, fn artifact ->
      artifact
      |> Canonical.to_canonical_map()
      |> Canonical.encode!()
    end)
  end

  defp fetch_string_key(map, field) do
    string_key = Atom.to_string(field)

    case Map.fetch(map, string_key) do
      {:ok, value} -> {:ok, value}
      :error -> {:error, "#{field} is required"}
    end
  end
end
