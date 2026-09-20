defmodule Tiannara.CEL.Services.ConstitutionalScorePipeline do
  use Tiannara.ExecutiveService.Base
  use GenServer
  require Logger

  @window_size 100

  def start_link(_opts), do: GenServer.start_link(__MODULE__, %{}, name: __MODULE__)

  def record_observation(service_id, scores) do
    GenServer.cast(__MODULE__, {:observe, service_id, scores})
  end

  def current_score(service_id) do
    GenServer.call(__MODULE__, {:current, service_id})
  end

  def all_scores, do: GenServer.call(__MODULE__, :all)

  @impl true
  def id, do: :constitutional_score_pipeline

  @impl true
  def version, do: "1.0.0"

  @impl true
  def capabilities, do: [:constitutional_scoring, :telemetry_analysis, :score_aggregation,
    :evidence_scoring, :constitutional_analytics]

  @impl true
  def health, do: :healthy

  @impl true
  def constitutional_score do
    %Tiannara.CEL.Kernel.ConstitutionalScore{
      service_id: :constitutional_score_pipeline,
      health: 1.0,
      constitutional_alignment: 1.0,
      transparency: 1.0,
      explainability: 1.0,
      evidence_quality: 0.95,
      human_oversight: 0.6,
      computed_at: DateTime.utc_now()
    }
  end

  @impl true
  def init(_opts) do
    :telemetry.attach_many(
      "constitutional-score-pipeline",
      [
        [:tiannara, :executive, :constitutional],
        [:tiannara, :cel, :event_bus, :published],
        [:tiannara, :cel, :memory, :recorded],
        [:tiannara, :cel, :mission, :completed]
      ],
      &handle_telemetry/4,
      self()
    )

    Logger.info("ConstitutionalScorePipeline: Telemetry-driven scoring pipeline initialized")
    {:ok, %{windows: %{}}}
  end

  @impl true
  def handle_cast({:observe, service_id, scores}, state) do
    window = Map.get(state.windows, service_id, [])
    new_window = [scores | window] |> Enum.take(@window_size)
    {:noreply, put_in(state, [:windows, service_id], new_window)}
  end

  @impl true
  def handle_call({:current, service_id}, _from, state) do
    window = Map.get(state.windows, service_id, [])
    score = aggregate_window(window, service_id)
    {:reply, score, state}
  end

  @impl true
  def handle_call(:all, _from, state) do
    scores =
      state.windows
      |> Enum.map(fn {service_id, window} -> {service_id, aggregate_window(window, service_id)} end)
      |> Map.new()

    {:reply, scores, state}
  end

  defp handle_telemetry(event, measurements, metadata, config) do
    service_id = Map.get(metadata, :service, :unknown)
    scores = extract_scores(event, measurements, metadata)
    GenServer.cast(config, {:observe, service_id, scores})
  end

  defp extract_scores([:tiannara, :executive, :constitutional], _measurements, metadata) do
    %{
      alignment: Map.get(metadata, :constitutional_alignment, 0.5),
      transparency: Map.get(metadata, :transparency, 0.5),
      evidence_quality: Map.get(metadata, :evidence_quality, 0.5),
      observed_at: DateTime.utc_now()
    }
  end

  defp extract_scores(_event, _measurements, _metadata) do
    %{
      alignment: 0.5,
      transparency: 0.5,
      evidence_quality: 0.5,
      observed_at: DateTime.utc_now()
    }
  end

  defp aggregate_window([], service_id) do
    %Tiannara.CEL.Kernel.ConstitutionalScore{
      service_id: service_id,
      health: 1.0,
      constitutional_alignment: 0.5,
      transparency: 0.5,
      explainability: 0.5,
      evidence_quality: 0.5,
      human_oversight: 0.5,
      computed_at: DateTime.utc_now()
    }
  end

  defp aggregate_window(window, service_id) do
    count = length(window)
    avg = fn key -> Enum.reduce(window, 0.0, fn s, acc -> acc + Map.get(s, key, 0.5) end) / count end

    %Tiannara.CEL.Kernel.ConstitutionalScore{
      service_id: service_id,
      health: 1.0,
      constitutional_alignment: avg.(:alignment),
      transparency: avg.(:transparency),
      explainability: avg.(:alignment) * 0.9,
      evidence_quality: avg.(:evidence_quality),
      human_oversight: 0.6,
      computed_at: DateTime.utc_now()
    }
  end
end
