defmodule Tiannara.CIS.PathogenDetector do
  @moduledoc """
  Analyzes telemetry for signatures of epistemic collapse.
  """
  require Logger
  alias Tiannara.CIS.ImmuneResponse
  alias Tiannara.CIS.OverreactionMonitor
  alias Tiannara.CIS.ImmuneMemory

  def evaluate(pathogen_type, payload) do
    # Consult Immune Memory for faster detection
    if ImmuneMemory.recognized?(pathogen_type) do
      Logger.debug("🧠 [CIS] Immune Memory matched signature for: #{pathogen_type}")
      Tiannara.Metrics.Aggregator.push_event([:tiannara, :cis, :immune_recall], 1.0)
    end
    
    # Analyze Payload
    # Overreaction Monitor prevents autoimmune collapse. A deployment failure
    # remains a failure; it is never converted into a successful metric.
    case OverreactionMonitor.veto_intervention?(pathogen_type, payload) do
      false ->
        ImmuneResponse.deploy(pathogen_type)
      true ->
        Logger.info("🛡️ [CIS] OverreactionMonitor vetoed intervention. Preserving innovation.")
        {:vetoed, :overreaction_risk}
    end
  end
end
