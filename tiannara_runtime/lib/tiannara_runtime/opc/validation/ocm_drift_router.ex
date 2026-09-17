defmodule Tiannara.OPC.Validation.OCMDriftRouter do
  @moduledoc """
  Handles evaluation of semantic drift after successful CTL validation and routes
  drift alerts through the NATS OCMBus.

  This module is deliberately lightweight: it extracts a drift metric from the
  compiled AST (placeholder implementation) and publishes a drift alert when the
  metric crosses the warning or critical thresholds defined by `TiannaraRuntime.OCM.DriftAnalyzer`.
  """

  require Logger
  alias TiannaraRuntime.NATS.OCMBus
  alias TiannaraRuntime.OCM.DriftAnalyzer

  @doc """
  Evaluate drift for `observer_id` using the given `ast` and publish a drift alert
  if the drift category is `:warning` or `:critical`.

  Returns `:ok` on success or `{:error, reason}` if publishing fails.
  """
  @spec evaluate_and_route(String.t(), term()) :: :ok | {:error, any()}
  def evaluate_and_route(observer_id, _ast) do
    # Placeholder: derive a simple vector from the AST depth/complexity.
    # For now we generate a pseudo‑random drift value to simulate analysis.
    drift = :rand.uniform()
    category = case drift do
      d when d >= 0.60 -> :critical
      d when d >= 0.35 -> :warning
      _ -> :stable
    end

    case category do
      :stable ->
        Logger.debug("[OCMDriftRouter] Drift stable (#{Float.round(drift, 3)}) for #{observer_id}")
        :ok
      _ ->
        Logger.info("[OCMDriftRouter] Publishing drift #{category} (#{Float.round(drift, 3)}) for #{observer_id}")
        # Using the observer as both nodes for simplicity.
        case OCMBus.publish_drift_alert(observer_id, observer_id, drift, category) do
          :ok -> :ok
          other -> {:error, other}
        end
    end
  end
end
