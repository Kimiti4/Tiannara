defmodule Tiannara.REA.Epistemic.CivilizationEvent do
  @derive Jason.Encoder
  defstruct [:id, :type, :epoch, :title, :description, :telemetry]
end

defmodule Tiannara.REA.Epistemic.CivilizationMemory do
  use GenServer
  alias Tiannara.REA.Epistemic.CivilizationEvent

  @file_path "data/civilization_memory.ndjson"

  def start_link(opts \\ []), do: GenServer.start_link(__MODULE__, opts, name: __MODULE__)

  # --- PUBLIC API ---

  def log_event(type, epoch, title, description, telemetry \\ %{}) do
    event = %CivilizationEvent{
      id: "event_#{epoch}_#{System.unique_integer([:positive])}",
      type: type,
      epoch: epoch,
      title: title,
      description: description,
      telemetry: telemetry
    }
    GenServer.call(__MODULE__, {:log, event})
  end

  def get_events do
    GenServer.call(__MODULE__, :get_events)
  end

  # Rule ARC1 Invariant: Bypasses standard reset/rollback of file system.
  # The GenServer memory can clear, but it immediately reloads from the persistent file.
  def reset do
    GenServer.call(__MODULE__, :reset)
  end

  # --- CALLBACKS ---

  @impl true
  def init(_opts) do
    {:ok, load_persisted_events()}
  end

  @impl true
  def handle_call({:log, event}, _from, state) do
    # Append to file
    File.mkdir_p!(Path.dirname(@file_path))
    line = Jason.encode!(event) <> "\n"
    File.write!(@file_path, line, [:append])

    # Keep in state
    {:reply, :ok, state ++ [event]}
  end

  @impl true
  def handle_call(:get_events, _from, state) do
    {:reply, state, state}
  end

  @impl true
  def handle_call(:reset, _from, _state) do
    # ARC1 Rule: Resetting does NOT delete the persistence file!
    # Instead, we just reload the existing history.
    {:reply, :ok, load_persisted_events()}
  end

  # --- HELPERS ---

  defp load_persisted_events do
    if File.exists?(@file_path) do
      @file_path
      |> File.stream!()
      |> Stream.map(&String.trim/1)
      |> Stream.reject(&(&1 == ""))
      |> Stream.map(fn line ->
        case Jason.decode(line, keys: :atoms) do
          {:ok, attrs} -> struct(CivilizationEvent, attrs)
          _ -> nil
        end
      end)
      |> Stream.reject(&is_nil/1)
      |> Enum.to_list()
    else
      []
    end
  end
end
