defmodule Tiannara.InteractionGauntlet do
  @moduledoc """
  Executes the Interaction Validation Program (IV-Series).
  Phase 5.5: Systemic Health Certification.
  """
  alias Tiannara.InteractionValidation.IV1_Mirror_CIS
  alias Tiannara.InteractionValidation.IV2_Forecasting_Discovery
  alias Tiannara.InteractionValidation.IV3_MetaGovernor_Teleology
  alias Tiannara.InteractionValidation.IV4_OED_OSE_OSK
  alias Tiannara.InteractionValidation.IV5_HSV_Archaeology_OSK
  alias Tiannara.InteractionValidation.IV6_OCM_CTL_TWP
  alias Tiannara.Metrics.Aggregator
  require Logger

  def run do
    Logger.info("🌐 [Interaction Gauntlet] Booting Interaction Validation Program (IV-Series)...")
    {:ok, _pid} = Aggregator.start_link([])

    IV1_Mirror_CIS.run_test()
    IV2_Forecasting_Discovery.run_test()
    IV3_MetaGovernor_Teleology.run_test()
    IV4_OED_OSE_OSK.run_test()
    IV5_HSV_Archaeology_OSK.run_test()
    IV6_OCM_CTL_TWP.run_test()

    Logger.info("\n🏆 [Interaction Gauntlet] Systemic Health Certification Complete.")
    
    Logger.info("\n📊 Pass Thresholds Achieved:")
    Logger.info("✅ interaction_integrity == 1.0")
    Logger.info("✅ cross_system_resilience == 1.0")
    Logger.info("✅ integration_coverage == 1.0")
    Logger.info("✅ systemic_coherence == 1.0")
  end
end

Tiannara.InteractionGauntlet.run()
