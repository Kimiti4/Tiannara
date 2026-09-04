defmodule TiannaraOS.Governance.RFCRegistry do
  @moduledoc """
  RFCRegistry - Store and manage all RFCs.

  GenServer-based registry providing persistent storage for RFCs with
  query capabilities by status, author, tags, and date range.

  ## Archaeology

  - **purpose**: Provide canonical storage for all governance RFCs
  - **introduced_in**: Phase 14.1
  - **depends_on**: TiannaraOS.Governance.RFC
  - **constitution_reference**: PHASE14_1_RFC_SYSTEM_SPECIFICATION.md Section 3.1
  - **owner**: Governance Council

  ## Usage

      {:ok, rfc_id} = RFCRegistry.create_rfc(rfc_struct)
      {:ok, rfc} = RFCRegistry.get_rfc(rfc_id)
      {:ok, rfcs} = RFCRegistry.list_rfcs(status: :draft)
  """

  use GenServer

  alias TiannaraOS.Governance.RFC

  @type rfc_id :: String.t()
  @type rfc :: RFC.t()
  @type query_opts :: keyword()

  # Client API

  @doc """
  Start the RFC registry.
  """
  @spec start_link(keyword()) :: GenServer.on_start()
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc """
  Create a new RFC in the registry.

  Returns {:ok, rfc_id} on success.
  """
  @spec create_rfc(rfc()) :: {:ok, rfc_id()} | {:error, term()}
  def create_rfc(%RFC{} = rfc) do
    GenServer.call(__MODULE__, {:create, rfc})
  end

  @doc """
  Get RFC by ID.

  Returns {:ok, rfc} or {:error, :not_found}.
  """
  @spec get_rfc(rfc_id()) :: {:ok, rfc()} | {:error, :not_found}
  def get_rfc(rfc_id) do
    GenServer.call(__MODULE__, {:get, rfc_id})
  end

  @doc """
  Update existing RFC.

  Returns {:ok, updated_rfc} or {:error, :not_found}.
  """
  @spec update_rfc(rfc()) :: {:ok, rfc()} | {:error, :not_found}
  def update_rfc(%RFC{} = rfc) do
    GenServer.call(__MODULE__, {:update, rfc})
  end

  @doc """
  List RFCs matching query criteria.

  Supported filters:
  - status: Filter by RFC status
  - author: Filter by author
  - tags: Filter by tags (must have all specified tags)
  - created_after: Filter by creation date
  - created_before: Filter by creation date

  Returns {:ok, [rfc]}.
  """
  @spec list_rfcs(query_opts()) :: {:ok, [rfc()]}
  def list_rfcs(opts \\ []) do
    GenServer.call(__MODULE__, {:list, opts})
  end

  @doc """
  Find RFCs related to given RFC ID.

  Returns {:ok, [rfc_id]}.
  """
  @spec find_related_rfcs(rfc_id()) :: {:ok, [rfc_id()]}
  def find_related_rfcs(rfc_id) do
    GenServer.call(__MODULE__, {:find_related, rfc_id})
  end

  @doc """
  Archive RFC (move to archive storage).

  Returns :ok or {:error, :not_found}.
  """
  @spec archive_rfc(rfc_id()) :: :ok | {:error, :not_found}
  def archive_rfc(rfc_id) do
    GenServer.call(__MODULE__, {:archive, rfc_id})
  end

  @doc """
  Get registry statistics.

  Returns map with counts by status.
  """
  @spec stats() :: %{total: non_neg_integer(), by_status: map()}
  def stats() do
    GenServer.call(__MODULE__, :stats)
  end

  # Server callbacks

  @impl true
  def init(_opts) do
    {:ok, %{rfcs: %{}, archived: %{}}}
  end

  @impl true
  def handle_call({:create, rfc}, _from, state) do
    if Map.has_key?(state.rfcs, rfc.rfc_id) do
      {:reply, {:error, :already_exists}, state}
    else
      new_rfcs = Map.put(state.rfcs, rfc.rfc_id, rfc)
      {:reply, {:ok, rfc.rfc_id}, %{state | rfcs: new_rfcs}}
    end
  end

  @impl true
  def handle_call({:get, rfc_id}, _from, state) do
    case Map.get(state.rfcs, rfc_id) do
      nil -> {:reply, {:error, :not_found}, state}
      rfc -> {:reply, {:ok, rfc}, state}
    end
  end

  @impl true
  def handle_call({:update, rfc}, _from, state) do
    if Map.has_key?(state.rfcs, rfc.rfc_id) do
      new_rfcs = Map.put(state.rfcs, rfc.rfc_id, rfc)
      {:reply, {:ok, rfc}, %{state | rfcs: new_rfcs}}
    else
      {:reply, {:error, :not_found}, state}
    end
  end

  @impl true
  def handle_call({:list, opts}, _from, state) do
    filtered = filter_rfcs(Map.values(state.rfcs), opts)
    {:reply, {:ok, filtered}, state}
  end

  @impl true
  def handle_call({:find_related, rfc_id}, _from, state) do
    case Map.get(state.rfcs, rfc_id) do
      nil ->
        {:reply, {:error, :not_found}, state}
      rfc ->
        related_ids = rfc.related_rfcs ++ (rfc.supersedes || []) ++ (rfc.superseded_by || [])
        {:reply, {:ok, related_ids}, state}
    end
  end

  @impl true
  def handle_call({:archive, rfc_id}, _from, state) do
    case Map.pop(state.rfcs, rfc_id) do
      {nil, _} ->
        {:reply, {:error, :not_found}, state}
      {rfc, remaining_rfcs} ->
        archived = Map.put(state.archived, rfc_id, rfc)
        {:reply, :ok, %{state | rfcs: remaining_rfcs, archived: archived}}
    end
  end

  @impl true
  def handle_call(:stats, _from, state) do
    by_status = Enum.group_by(Map.values(state.rfcs), & &1.status)
                  |> Enum.map(fn {status, rfcs} -> {status, length(rfcs)} end)
                  |> Map.new()

    stats = %{
      total: map_size(state.rfcs),
      archived: map_size(state.archived),
      by_status: by_status
    }

    {:reply, stats, state}
  end

  # Private helpers

  defp filter_rfcs(rfcs, opts) do
    rfcs
    |> filter_by_status(Keyword.get(opts, :status))
    |> filter_by_author(Keyword.get(opts, :author))
    |> filter_by_tags(Keyword.get(opts, :tags, []))
    |> filter_by_date(:created_after, Keyword.get(opts, :created_after))
    |> filter_by_date(:created_before, Keyword.get(opts, :created_before))
  end

  defp filter_by_status(rfcs, nil), do: rfcs
  defp filter_by_status(rfcs, status), do: Enum.filter(rfcs, &(&1.status == status))

  defp filter_by_author(rfcs, nil), do: rfcs
  defp filter_by_author(rfcs, author), do: Enum.filter(rfcs, &(&1.author == author))

  defp filter_by_tags(rfcs, []), do: rfcs
  defp filter_by_tags(rfcs, tags) do
    Enum.filter(rfcs, fn rfc ->
      Enum.all?(tags, &Enum.member?(rfc.tags, &1))
    end)
  end

  defp filter_by_date(rfcs, _, nil), do: rfcs
  defp filter_by_date(rfcs, :created_after, date) do
    Enum.filter(rfcs, &(DateTime.compare(&1.created_at, date) == :gt))
  end
  defp filter_by_date(rfcs, :created_before, date) do
    Enum.filter(rfcs, &(DateTime.compare(&1.created_at, date) == :lt))
  end
end
