defmodule Tiannara.CRAV.SoakCheckpointer do
  use GenServer
  require Logger

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def save(state), do: GenServer.call(__MODULE__, {:save, state})

  def load, do: GenServer.call(__MODULE__, :load)

  def healthy?, do: GenServer.call(__MODULE__, :healthy)

  @impl true
  def init(_opts) do
    File.mkdir_p!(checkpoint_dir())
    {:ok, %{last_checkpoint: nil, saves: 0}}
  end

  @impl true
  def handle_call({:save, state}, _from, current) do
    checkpoint = %{
      timestamp: DateTime.utc_now() |> DateTime.to_iso8601(),
      state: scrub_for_persistence(state)
    }

    File.write!(checkpoint_file(), Jason.encode!(checkpoint, pretty: true))
    {:reply, :ok, %{current | last_checkpoint: checkpoint, saves: current.saves + 1}}
  end

  @impl true
  def handle_call(:load, _from, current) do
    result =
      case File.read(checkpoint_file()) do
        {:ok, content} ->
          case Jason.decode(content) do
            {:ok, data} -> {:ok, data["state"]}
            {:error, _} -> {:error, :corrupt_checkpoint}
          end

        {:error, _} ->
          {:error, :no_checkpoint}
      end

    {:reply, result, current}
  end

  @impl true
  def handle_call(:healthy, _from, current) do
    {:reply, File.exists?(checkpoint_dir()), current}
  end

  defp checkpoint_dir, do: Tiannara.Storage.Paths.path("checkpoints")
  defp checkpoint_file, do: Tiannara.Storage.Paths.path("checkpoints/latest.json")

  defp scrub_for_persistence(state) when is_map(state) do
    state
    |> Map.drop([:__struct__])
    |> Enum.map(fn {k, v} -> {k, scrub_value(v)} end)
    |> Map.new()
  end

  defp scrub_value(v) when is_pid(v), do: inspect(v)
  defp scrub_value(v) when is_function(v), do: nil
  defp scrub_value(v) when is_reference(v), do: inspect(v)
  defp scrub_value(v) when is_map(v), do: scrub_for_persistence(v)
  defp scrub_value(v) when is_list(v), do: Enum.map(v, &scrub_value/1)
  defp scrub_value(v) when is_tuple(v), do: Tuple.to_list(v) |> scrub_value()
  defp scrub_value(v), do: v
end
