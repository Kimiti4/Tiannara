defmodule TiannaraRuntime.AutonomousResearch.Phase16_1.QuestionArchive do
  @moduledoc """
  Phase 16.1 Module 2 — Question Archive (Pure Implementation)

  Tracks lifecycle of research questions:
  - active: currently being investigated
  - resolved: answered with sufficient evidence
  - archived: no longer relevant
  - abandoned: failed or deprecated

  Deterministic ordering enforced.
  """

  @archive_table :question_archive

  def init_table do
    if :ets.info(@archive_table) == :undefined do
      :ets.new(@archive_table, [:set, :public, :named_table])
    end
    :ok
  end

  @doc "Mark a question as active"
  @spec activate(String.t(), map()) :: :ok
  def activate(question_id, metadata \\ %{}) do
    init_table()
    record = build_record(question_id, "ACTIVE", metadata)
    :ets.insert(@archive_table, {question_id, record})
    :ok
  end

  @doc "Mark a question as resolved"
  @spec resolve(String.t(), map()) :: :ok
  def resolve(question_id, metadata \\ %{}) do
    record = build_record(question_id, "RESOLVED", metadata)
    :ets.insert(@archive_table, {question_id, record})
    :ok
  end

  @doc "Mark a question as archived"
  @spec archive(String.t(), map()) :: :ok
  def archive(question_id, metadata \\ %{}) do
    record = build_record(question_id, "ARCHIVED", metadata)
    :ets.insert(@archive_table, {question_id, record})
    :ok
  end

  @doc "Mark a question as abandoned"
  @spec abandon(String.t(), map()) :: :ok
  def abandon(question_id, metadata \\ %{}) do
    record = build_record(question_id, "ABANDONED", metadata)
    :ets.insert(@archive_table, {question_id, record})
    :ok
  end

  @doc "Lookup question status"
  @spec lookup(String.t()) :: {:ok, map()} | :error
  def lookup(question_id) when is_binary(question_id) do
    case :ets.lookup(@archive_table, question_id) do
      [{^question_id, record}] -> {:ok, record}
      [] -> :error
    end
  end

  @doc "Query questions by status"
  @spec query_by_status(String.t()) :: [map()]
  def query_by_status(status) do
    :ets.tab2list(@archive_table)
    |> Enum.map(fn {_id, r} -> r end)
    |> Enum.filter(fn r -> Map.get(r, "status") == status end)
  end

  @doc "List all archived questions"
  @spec list_all() :: [map()]
  def list_all do
    :ets.tab2list(@archive_table)
    |> Enum.map(fn {_id, r} -> r end)
  end

  # --- internal helpers ---

  defp build_record(question_id, status, metadata) do
    canonical = canonicalize_map(%{"question_id" => question_id, "status" => status})
    json = Jason.encode!(canonical)
    archive_id = "arch_q_" <> (:crypto.hash(:sha256, json) |> Base.encode16(case: :lower))

    %{
      "archive_id" => archive_id,
      "question_id" => question_id,
      "status" => status,
      "schema_version" => "16.1.0",
      "metadata" => metadata
    }
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
