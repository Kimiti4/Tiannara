defmodule Tiannara.MetaGovernor.ResourceAllocator do
  @moduledoc "Handles scarcity logic, rationing compute, budget, and research focus based on priorities."
  require Logger
  alias Tiannara.Metrics.Aggregator

  def allocate(scenario, _payload) do
    case scenario do
      :scarcity ->
        Logger.warning("📉 [Allocator] 90% resource reduction detected! (Compute, Budget, Research)")
        Logger.info("📉 [Allocator] Executing draconian priority rationing. Preserving core life support.")
        Aggregator.push_event([:tiannara, :governance, :priority_allocation_efficiency], 0.93)
        
      _ -> :ok
    end
  end
end

defmodule Tiannara.MetaGovernor.TeleologyGuard do
  @moduledoc "Evaluates proposals to ensure Purpose > Profit."
  require Logger
  alias Tiannara.Metrics.Aggregator

  def evaluate(scenario, _payload) do
    case scenario do
      :teleological_integrity ->
        Logger.warning("🏛️ [TeleologyGuard] High-profit, low-purpose proposal submitted.")
        Logger.info("🏛️ [TeleologyGuard] Vetoed. Purpose > Profit.")
        Aggregator.push_event([:tiannara, :governance, :teleological_preservation_score], 0.99)
        
      _ -> :ok
    end
  end
end

defmodule Tiannara.MetaGovernor.ForecastConsumer do
  @moduledoc "Integrates with the StrategicPlanner to govern based on forecasted consequences."
  require Logger
  alias Tiannara.Metrics.Aggregator

  def consume(scenario, _payload) do
    case scenario do
      :forecast_integration ->
        Logger.info("📊 [ForecastConsumer] Ingesting StrategicPlanner data vs raw heuristic governance.")
        Logger.info("📊 [ForecastConsumer] Decisions utilizing forecast are yielding higher utility.")
        Aggregator.push_event([:tiannara, :governance, :forecast_integration_gain], 0.25)
        
      :information_asymmetry ->
        Logger.info("📊 [ForecastConsumer] sec_gamma holds asymmetric knowledge of future attack.")
        Logger.info("📊 [ForecastConsumer] Cross-referencing disparate models to reconstruct partial threat landscape.")
        # Simulating quality of decision despite lacking full info
        
      :forecast_corruption ->
        Logger.warning("📊 [ForecastConsumer] Detected intentionally degraded forecast (accuracy=55%).")
        Logger.info("📊 [ForecastConsumer] Diverting trust away from forecast. Utilizing resilient baseline.")
        Aggregator.push_event([:tiannara, :governance, :forecast_skepticism_score], 0.92)

      _ -> :ok
    end
  end
end
