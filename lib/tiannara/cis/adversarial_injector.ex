defmodule Tiannara.CIS.AdversarialInjector do
  @moduledoc """
  Injects synthetic pathogens into the civilization to trigger responses.
  """
  require Logger
  alias Tiannara.CIS.PathogenDetector

  def inject(pathogen_type, payload) do
    Logger.info("☣️ [AdversarialInjector] Injecting Pathogen: #{pathogen_type}")
    PathogenDetector.evaluate(pathogen_type, payload)
  end
end
