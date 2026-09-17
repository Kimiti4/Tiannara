defmodule ObservationBus.CIL.Epistemic.BiasDetector do
  @moduledoc """
  Measures epistemic biases across the constitutional knowledge ecosystem.

  Detects: theory bias, sampling bias, confirmation bias, domain imbalance,
  experiment imbalance, and knowledge monoculture.
  """
  use GenServer

  @table_name :cil_bias_metrics

  @bias_types ~w(theory_bias sampling_bias confirmation_bias
                  domain_imbalance experiment_imbalance knowledge_monoculture)a

  defstruct [:table, :total_measurements]

  @doc false
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    table = :ets.new(@table_name, [:set, :public, :named_table,
                                   write_concurrency: true, read_concurrency: true])
    biases = Enum.into(@bias_types, %{}, fn bt -> {bt, default_measure(bt)} end)
    Enum.each(biases, fn {k, v} -> :ets.insert(table, {k, v}) end)
    {:ok, %{table: table, total_measurements: 0}}
  end

  @doc "Record a bias measurement."
  @spec measure(atom(), float(), map()) :: :ok
  def measure(bias_type, score, metadata \\ %{}) when bias_type in @bias_types do
    GenServer.cast(__MODULE__, {:measure, bias_type, score, metadata})
  end

  @doc "Get current bias readings."
  @spec readings() :: [map()]
  def readings do
    @table_name
    |> :ets.tab2list()
    |> Enum.map(fn {_k, v} -> v end)
    |> Enum.sort_by(& &1.score, :desc)
  end

  @doc "Get overall bias index."
  @spec bias_index() :: float()
  def bias_index do
    readings = readings()
    scores = Enum.map(readings, & &1.score)
    if length(scores) > 0, do: Enum.sum(scores) / length(scores), else: 0.0
  end

  @impl true
  def handle_cast({:measure, bias_type, score, metadata}, state) do
    entry = %{
      bias_type: bias_type, score: max(0.0, min(1.0, score)),
      metadata: metadata, measured_at: DateTime.utc_now()
    }
    :ets.insert(@table_name, {bias_type, entry})
    {:noreply, %{state | total_measurements: state.total_measurements + 1}}
  end

  defp default_measure(bt) do
    %{bias_type: bt, score: 0.0, metadata: %{}, measured_at: DateTime.utc_now()}
  end
end
