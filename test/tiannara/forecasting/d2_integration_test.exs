defmodule Tiannara.Forecasting.D2IntegrationTest do
  use ExUnit.Case, async: false

  alias Tiannara.Forecasting.{Signal, SignalRegistry, Forecast, ForecastEngine, ForecastRegistry,
                             Outcome, Calibration, BaseRateEngine}
  alias Tiannara.Forecasting.Adapters.{ResearchImpl, EvidenceImpl, CISImpl, WorldModelImpl}

  setup do
    start_supervised!(SignalRegistry)
    start_supervised!(ForecastRegistry)
    :ets.delete_all_objects(:efdi_signal_registry)
    :ets.delete_all_objects(:efdi_forecast_registry)
    :ok
  end

  defp signal(attrs) do
    m = Map.new(attrs)
    Signal.new(Map.put(m, :id, m[:id] || "sig_#{System.unique_integer([:positive])}"))
  end

  describe "Signal → Evidence → Forecast → Outcome → Calibration (full pipeline)" do
    test "a base-rate-informed forecast scores against the observed outcome" do
      {:ok, s1} = SignalRegistry.register(signal(source: :market, observation: 0.82, domain: :economics))
      {:ok, s2} = SignalRegistry.register(signal(source: :analyst, observation: 0.6, domain: :economics))

      # 2. Link each signal to existing evidence (no parallel ontology)
      {:ok, link1} = EvidenceImpl.link_to_evidence(s1, "ev_report_201", :supports)
      assert link1.evidence_id == "ev_report_201"
      assert {:ok, [_]} = EvidenceImpl.evidence_for_id(s1.id)

      # 3. Base rate
      br = BaseRateEngine.new(reference_class: "similar_projects",
                              historical_frequency: 0.55, data_quality: :medium,
                              base_rate_uncertainty: 0.1)

      # 4. Forecast referencing both signal and evidence
      {:ok, f} =
        ForecastEngine.forecast(
          question: "Is the project on track for delivery?",
          event: "delivery_on_track",
          outcomes: ["on_track", "not_on_track"],
          horizon: 30,
          base_rate: br,
          signal_ids: [s1.id, s2.id],
          evidence_ids: ["ev_report_201"],
          regime: :steady_state
        )

      assert f.signal_refs == [s1.id, s2.id]
      assert f.evidence_refs == ["ev_report_201"]
      assert {:ok, f} = ForecastRegistry.register(f)

      # 5. Outcome observed post-forecast (hindsight-clean)
      {:ok, outcome} =
        Outcome.new(f.id, "on_track", source: "delivery_wire")
        |> Map.put(:observed_at, DateTime.add(f.created_at, 31, :day))
        |> Outcome.guard!(f)

      assert Outcome.hindsight_clean?(outcome, f)

      # 6. Single-observation score is honest (sample_size 1, not over-claimed)
      score = Calibration.score(f, "on_track")
      assert score.sample_size == 1
      assert is_number(score.value)
      ideal = (Enum.at(f.probabilities, 0) - 1) ** 2
      assert_in_delta(score.value, ideal, 1.0e-9)
      assert Calibration.reliability_level(1) == :insufficient
    end

    test "collective calibration over many questions tracks the true base rate" do
      pairs =
        for _ <- 1..200 do
          {:ok, f} =
            ForecastEngine.forecast(
              question: "Rate event?",
              event: "evt_#{System.unique_integer([:positive])}",
              outcomes: ["hit", "miss"],
              horizon: 1,
              base_rate: BaseRateEngine.new(reference_class: "rate", historical_frequency: 0.6)
            )

          observed = if :rand.uniform() < 0.6, do: "hit", else: "miss"
          {f, observed}
        end

      mb = Calibration.mean_brier(pairs)
      # strictly better than a coin-flip
      assert mb < 0.25
      # close to ideal (0.6,1)²·0.6 + (0.6,0)²·0.4
      ideal = 0.6 * 0.16 + 0.4 * 0.36
      assert abs(mb - ideal) < 0.03
      assert Calibration.reliability_level(length(pairs)) == :adequate
    end

    test "hindsight-contaminated outcomes are never linked" do
      f = Forecast.new(question: "Q", event: "e", outcomes: ["yes", "no"], probabilities: [0.8, 0.2])
      early = DateTime.add(f.created_at, -5, :hour)
      bad = Outcome.new(f.id, "yes", observed_at: early)
      assert {:error, :hindsight_contamination} = Outcome.guard!(bad, f)
    end
  end

  describe "adapter implementations (D2)" do
    test "ResearchImpl yields ResearchDirector-compatible priorities" do
      s = signal(source: :survey, observation: 0.9, domain: :biology,
                 relevance: 0.8, reliability: 0.7, predictive_value: 0.6)
      {:ok, p} = ResearchImpl.signal_to_priority(s)
      assert p.domain == :biology
      assert p.signal == s.id
      assert p.score >= 0 and p.score <= 1

      {:ok, many} = ResearchImpl.signals_to_priorities([s, signal(source: :a, observation: 1)])
      assert length(many) == 2
    end

    test "ResearchImpl reports under-observed regions" do
      sigs = [signal(source: :a, observation: 1, domain: :bio),
              signal(source: :b, observation: 2, domain: :bio),
              signal(source: :c, observation: 3, domain: :astro)]
      {:ok, regions} = ResearchImpl.under_observed_regions(sigs)
      bio = Enum.find(regions, &(&1.domain == :bio))
      assert bio.signal_count == 2
    end

    test "ResearchImpl information gain estimate is honest" do
      s = signal(source: :a, observation: 0.5, domain: :physics)
      assert {:error, :insufficient_data} = ResearchImpl.information_gain_estimate(s, [])
    end

    test "CISImpl converts signals→telemetry and forecast→collapse probability" do
      {:ok, t} = CISImpl.signal_to_telemetry(signal(source: :wm, observation: 0.3, domain: :cosmos,
                                                    source_reliability: 0.9))
      assert t.source == :wm
      assert t.reliability == 0.9

      f = Forecast.new(question: "Q", event: "e", outcomes: ["yes", "no"], probabilities: [0.9, 0.1])
      {:ok, cp} = CISImpl.forecast_to_collapse_probability(%{probabilities: f.probabilities})
      assert is_number(cp) and cp >= 0 and cp <= 1

      assert {:error, :insufficient_signals} =
               CISImpl.signal_conflict_to_pathogen([signal(source: :x, observation: 1)])

      {:ok, pathogen} =
        CISImpl.signal_conflict_to_pathogen([signal(source: :x, observation: 1),
                                             signal(source: :y, observation: 0)])
      assert pathogen.degeneracy_observed == true
    end

    test "WorldModelImpl does not claim world-conflict it cannot see" do
      s = signal(source: :orbit, observation: 0.4, domain: :cosmos)
      assert {:ok, _} = WorldModelImpl.ingest_signal(s)
      assert {:ok, ctx} = WorldModelImpl.context_for(s)
      assert ctx.domain == :cosmos
      assert {:error, :world_snapshot_unavailable} = WorldModelImpl.conflicts_with_world?(s)
    end
  end

  describe "immutable versioning" do
    test "a corrected forecast references its ancestor, never overwrites" do
      {:ok, v1} =
        ForecastEngine.forecast(question: "Q", event: "e", outcomes: ["yes", "no"], horizon: 30,
                                base_rate: BaseRateEngine.new(reference_class: "r", historical_frequency: 0.5))

      {:ok, _} = ForecastRegistry.register(v1)
      v2 = Forecast.version(v1, probabilities: [0.9, 0.1])

      assert v2.forecast_version == 2
      assert v2.lineage == [v1.id]
      assert {:ok, stored} = ForecastRegistry.get(v1.id)
      assert stored.probabilities == v1.probabilities
    end
  end
end