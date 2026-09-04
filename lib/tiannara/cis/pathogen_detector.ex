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
    Tiannara.Metrics.Aggregator.push_event([:tiannara, :cis, :immune_precision], 1.0)
    
    # Overreaction Monitor prevents autoimmune collapse
    case OverreactionMonitor.veto_intervention?(pathogen_type, payload) do
      false ->
        ImmuneResponse.deploy(pathogen_type)
      true ->
        Logger.info("🛡️ [CIS] OverreactionMonitor VETOED intervention. Preserving innovation.")
        Tiannara.Metrics.Aggregator.push_event([:tiannara, :cis, :innovation_preservation_rate], 1.0)
    end
  end
end
