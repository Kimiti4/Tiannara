defmodule Tiannara.Council.ConstitutionRepository do
  use GenServer
  require Logger

  alias Tiannara.Council.Constitution

  @table :constitution_repository
  @file_path ~c"./constitution_repository.dets"

  def start_link(_opts), do: GenServer.start_link(__MODULE__, %{}, name: __MODULE__)

  def current, do: GenServer.call(__MODULE__, :current)
  def get_version(version), do: GenServer.call(__MODULE__, {:get_version, version})
  def history, do: GenServer.call(__MODULE__, :history)

  def commit(constitution, amendment_id, committed_by) do
    GenServer.call(__MODULE__, {:commit, constitution, amendment_id, committed_by})
  end

  def rollback(target_version, actor), do: GenServer.call(__MODULE__, {:rollback, target_version, actor})

  @impl true
  def init(_opts) do
    {:ok, _} = :dets.open_file(@table, type: :set, file: @file_path)

    case :dets.lookup(@table, "1.0.0") do
      [] ->
        v1 = Constitution.v1()
        :dets.insert(@table, {"1.0.0", v1, nil, :human_founders, DateTime.utc_now()})
        Logger.info("ConstitutionRepository: seeded with v1.0.0")
      _ -> :ok
    end

    current_version = find_latest_version()
    {:ok, %{current_version: current_version}}
  end

  @impl true
  def handle_call(:current, _from, state) do
    case :dets.lookup(@table, state.current_version) do
      [{_v, constitution, _amend_id, _by, _ts}] -> {:reply, constitution, state}
      [] -> {:reply, {:error, :not_found}, state}
    end
  end

  @impl true
  def handle_call({:get_version, version}, _from, state) do
    case :dets.lookup(@table, version) do
      [{_v, constitution, _amend_id, _by, _ts}] -> {:reply, {:ok, constitution}, state}
      [] -> {:reply, {:error, :not_found}, state}
    end
  end

  @impl true
  def handle_call(:history, _from, state) do
    versions =
      :dets.traverse(@table, fn {v, _c, amend_id, by, ts} ->
        {:continue, %{version: v, amendment_id: amend_id, committed_by: by, committed_at: ts}}
      end)
      |> Enum.sort_by(& &1.version)

    {:reply, versions, state}
  end

  @impl true
  def handle_call({:commit, constitution, amendment_id, committed_by}, _from, state) do
    version = constitution.version
    :dets.insert(@table, {version, constitution, amendment_id, committed_by, DateTime.utc_now()})

    :telemetry.execute([:tiannara, :council, :constitution, :committed], %{}, %{
      version: version,
      amendment_id: amendment_id
    })

    Logger.info("ConstitutionRepository: committed v#{version}")
    {:reply, {:ok, version}, %{state | current_version: version}}
  end

  @impl true
  def handle_call({:rollback, target_version, actor}, _from, state) do
    case :dets.lookup(@table, target_version) do
      [{_v, _constitution, _amend_id, _by, _ts}] ->
        :telemetry.execute([:tiannara, :council, :constitution, :rollback], %{}, %{
          from: state.current_version,
          to: target_version,
          actor: actor
        })
        Logger.warning("ConstitutionRepository: rollback to v#{target_version} by #{inspect(actor)}")
        {:reply, :ok, %{state | current_version: target_version}}

      [] ->
        {:reply, {:error, :version_not_found}, state}
    end
  end

  defp find_latest_version do
    :dets.traverse(@table, fn {v, _c, _a, _b, _ts} -> {:continue, v} end)
    |> Enum.sort()
    |> List.last()
    |> Kernel.||("1.0.0")
  end
end
