defmodule Tiannara.Forecasting do
  @moduledoc """
  Epistemic Forecasting, Signal & Decision Intelligence (EFDI) — D1 Signal
  Intelligence.

  D1 establishes the foundational contract layer for the eventual D1-D6 EFDI
  subsystem:

      D1 Signal Intelligence      (this package)
      D2 Forecast + Calibration
      D3 Decision Intelligence
      D4 Counterfactual / Alternative Histories
      D5 Noise + Robustness
      D6 Forecast Memory / Institutional Learning

  EFDI is NOT a standalone prediction service and NOT a new canonical domain. It is
  an epistemic layer over Tiannara's existing mathematical, evidence, research,
  world-model, CIS and memory systems. Mathematics remains the foundational
  reasoning substrate.

  This root module is the public API facade for D1.

  Constitutional rule carried throughout: a signal is NOT a prediction, and a
  prediction is NOT a fact. UNKNOWN is a valid result; unmeasured is distinct from
  measured-and-low.

  D2-D6 are implemented in later packages. D1 STOPS here and does not forecast,
  calibrate, decide, or build forecast memory.
  """

  alias Tiannara.Forecasting.{Signal, SignalRegistry, SignalQuality, SignalValue,
                              ForecastEngine, ForecastRegistry, Calibration,
                              DecisionEngine, DecisionRegistry, Contracts,
                              Counterfactual, AlternativeHistory, Attribution,
                              Selection, RegressionToMean, TemporalFirewall}

  @spec start_link(Keyword.t()) :: GenServer.on_start()
  def start_link(opts \\ []) do
    SignalRegistry.start_link(opts)
  end

  @spec register_signal(map() | Signal.t()) :: {:ok, Signal.t()} | {:error, term()}
  def register_signal(%Signal{} = signal), do: SignalRegistry.register(signal)
  def register_signal(attrs) when is_map(attrs) or is_list(attrs), do: SignalRegistry.register(Signal.new(attrs))

  @spec get_signal(String.t()) :: {:ok, Signal.t()} | :error
  def get_signal(id), do: SignalRegistry.get(id)

  @spec signal_quality(Signal.t() | String.t()) :: SignalQuality.t()
  def signal_quality(%Signal{} = signal), do: SignalQuality.evaluate(signal)
  def signal_quality(id) when is_binary(id) do
    case SignalRegistry.get(id) do
      {:ok, s} -> SignalQuality.evaluate(s)
      :error -> :error
    end
  end

  @spec signal_value(Signal.t()) :: SignalValue.t()
  def signal_value(%Signal{} = signal), do: SignalValue.measure(signal)

  @spec stats() :: map()
  def stats, do: SignalRegistry.stats()

  @spec health() :: map()
  def health, do: SignalRegistry.health()

  @spec status() :: map()
  def status do
    %{
      package: :d1_signal_intelligence_and_d2_forecasting_and_d3_decision_intelligence_and_d4_counterfactual,
      implemented: [:signal, :registry, :quality, :value, :provenance, :correlation,
                    :contracts, :forecast, :base_rate, :registry_forecasts, :calibration,
                    :outcome, :versioning,
                    :decision, :decision_engine, :decision_registry, :decision_snapshot,
                    :decision_quality, :decision_review, :pre_mortem, :value_of_information,
                    :counterfactual, :alternative_history, :attribution, :selection,
                    :regression_to_mean, :temporal_firewall],
      deferred: [:noise, :memory]
    }
  end

  @doc "D2: generate a probabilistic forecast from a request."
  @spec forecast(map() | Contracts.ForecastRequest.t()) :: {:ok, Contracts.Forecast.t()} | {:error, term()}
  def forecast(req), do: ForecastEngine.forecast(req)

  @doc "D2: register a forecast (immutable)."
  @spec register_forecast(Contracts.Forecast.t()) :: {:ok, Contracts.Forecast.t()} | {:error, term()}
  def register_forecast(%Contracts.Forecast{} = f), do: ForecastRegistry.register(f)

  @doc "D2: retrieve a forecast by id."
  @spec get_forecast(String.t()) :: {:ok, Contracts.Forecast.t()} | :error
  def get_forecast(id) when is_binary(id), do: ForecastRegistry.get(id)

  @doc "D2: score a forecast (Brier / log_loss)."
  def score_forecast(%Contracts.Forecast{} = f, observed), do: Calibration.score(f, observed)

  @doc "D3: build and analyze a decision (expected value, risk, recommendation)."
  @spec decide(map() | Contracts.DecisionRequest.t()) ::
          {:ok, Contracts.Decision.t()} | {:error, term()}
  def decide(req), do: DecisionEngine.decide(req)

  @doc "D3: register a decision (immutable)."
  @spec register_decision(Contracts.Decision.t()) :: {:ok, Contracts.Decision.t()} | {:error, term()}
  def register_decision(%Contracts.Decision{} = d), do: DecisionRegistry.register(d)

  @doc "D3: retrieve a decision by id."
  @spec get_decision(String.t()) :: {:ok, Contracts.Decision.t()} | :error
  def get_decision(id) when is_binary(id), do: DecisionRegistry.get(id)

  # ------------------------------------------------------------------
  # D4: Counterfactual / Alternative Histories
  # ------------------------------------------------------------------

  @doc "D4: build a counterfactual record."
  @spec counterfactual_record(map()) :: Contracts.CounterfactualRecord.t()
  def counterfactual_record(attrs), do: Counterfactual.new(attrs)

  @doc "D4: build an alternative-history bundle for a decision."
  @spec alternative_history(Contracts.Decision.t(), Keyword.t()) :: Contracts.AlternativeHistoryBundle.t()
  def alternative_history(%Contracts.Decision{} = d, opts \\ []), do: AlternativeHistory.new(d, opts)

  @doc "D4: run bounded luck/skill attribution over repeated outcomes."
  @spec attribution(Contracts.Decision.t(), [Contracts.DecisionOutcome.t()], Keyword.t()) ::
          Contracts.AttributionReport.t()
  def attribution(%Contracts.Decision{} = d, outcomes, opts \\ []), do: Attribution.analyze(d, outcomes, opts)

  @doc "D4: analyze survivorship / selection."
  @spec selection(map() | list(), Keyword.t()) :: Contracts.SelectionEffectReport.t()
  def selection(population, opts \\ []), do: Selection.analyze(population, opts)

  @doc "D4: regression-to-the-mean analysis."
  @spec regression_to_mean([number()], map() | nil) :: Contracts.RegressionToMeanReport.t()
  def regression_to_mean(obs, ref \\ nil), do: RegressionToMean.analyze(obs, ref)

  @doc "D4: verify the D4→D3 temporal firewall."
  @spec verify_firewall(Contracts.Decision.t(), Tiannara.Forecasting.DecisionSnapshot.t(), list()) :: map()
  def verify_firewall(%Contracts.Decision{} = d, snap, artifacts \\ []),
    do: TemporalFirewall.verify(d, snap, artifacts)
end
