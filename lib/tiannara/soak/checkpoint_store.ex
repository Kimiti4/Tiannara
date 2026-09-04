defmodule Tiannara.Soak.CheckpointStore do
  @moduledoc """
  Persistence contract for soak checkpoints.

  ISOLATION CONTRACT:
    The store MUST be scoped to an isolated, run-specific directory and MUST
    refuse the production checkpoint path. This is the direct fix for the
    contamination bug where a crashed run's checkpoint was overwritten because
    the soak used the production checkpoint path.

  Lineage:
    Writes are append-only, versioned, atomic files so a corrupted latest
    checkpoint can fall back to the previous valid one.
  """

  alias Tiannara.Soak.Checkpoint

  @callback open(data_dir :: Path.t(), run_id :: String.t(), opts :: keyword()) ::
              {:ok, store :: term()} | {:error, term()}
  @callback write(store :: term(), checkpoint :: Checkpoint.t()) :: :ok | {:error, term()}
  @callback latest_valid(store :: term()) :: {:ok, Checkpoint.t()} | :none
  @callback lineage(store :: term()) :: [Checkpoint.t()]
end

defmodule Tiannara.Soak.CheckpointStore.IsolatedFileStore do
  @moduledoc """
  File-backed store using atomic write-then-rename and a versioned lineage so
  a torn write or corrupted latest checkpoint never destroys recovery ability.
  Refuses the production checkpoint path.
  """

  @behaviour Tiannara.Soak.CheckpointStore

  alias Tiannara.Soak.Checkpoint

  @production_checkpoint_path "checkpoints/production"

  defstruct [:data_dir, :run_id]

  @impl true
  def open(data_dir, run_id, _opts \\ []) do
    with :ok <- ensure_not_production(data_dir),
         :ok <- File.mkdir_p(data_dir) do
      {:ok, %__MODULE__{data_dir: data_dir, run_id: run_id}}
    end
  end

  defp ensure_not_production(data_dir) do
    normalized = Path.expand(data_dir)
    prod = Path.expand(@production_checkpoint_path)

    if normalized == prod or String.starts_with?(normalized, prod <> "/") do
      {:error, :production_path_forbidden}
    else
      :ok
    end
  end

  @impl true
  def write(%__MODULE__{data_dir: dir}, %Checkpoint{} = cp) do
    final = Path.join(dir, "checkpoint-#{cp.created_at}.bin")
    tmp = final <> ".tmp"

    with :ok <- File.write(tmp, Checkpoint.serialize(cp)),
         :ok <- File.rename(tmp, final) do
      :ok
    end
  end

  @impl true
  def latest_valid(%__MODULE__{} = store) do
    case Enum.find(lineage(store), &Checkpoint.valid?/1) do
      nil -> :none
      cp -> {:ok, cp}
    end
  end

  @impl true
  def lineage(%__MODULE__{data_dir: dir}) do
    dir
    |> File.ls!()
    |> Enum.filter(&String.starts_with?(&1, "checkpoint-"))
    |> Enum.sort_by(&parse_seq/1, :desc)
    |> Enum.flat_map(fn name ->
      with {:ok, bin} <- File.read(Path.join(dir, name)),
           {:ok, cp} <- Checkpoint.deserialize(bin) do
        [cp]
      else
        _ -> []
      end
    end)
  end

  defp parse_seq("checkpoint-" <> rest) do
    rest |> String.replace_suffix(".bin", "") |> String.to_integer()
  end
end
