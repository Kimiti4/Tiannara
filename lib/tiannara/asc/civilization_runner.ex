defmodule Tiannara.ASC.CivilizationRunner do
  require Logger

  alias Tiannara.Operations.CampaignIntegration

  defp emit(:phase_run, phase, dur, ok) do
    :telemetry.execute([:tiannara, :campaign, :phase_run], %{duration_ms: dur}, %{phase: phase, ok: ok})
  end

  @campaigns [
    phase6:  {Tiannara.ASC.Research.ResearchPortfolioManager, :run_campaign, []},
    phase7:  {Tiannara.ASC.MetaScience.MetaScienceCampaign, :run, []},
    phase8a: {Tiannara.ASC.Engineering.AutonomousEngineeringCampaign, :run, []},
    phase8b: {Tiannara.ASC.Reality.RealityAnchoredCampaign, :run, []},
    phase9:  {Tiannara.ASC.Civilization.AutonomousGuildCampaign, :run, []},
    phase10: {Tiannara.ASC.Delivery.ProductDeliveryCampaign, :run, []}
  ]

  @doc "Runs all campaigns in sequence from Phase 6 through Phase 10."
  def run_all do
    Logger.info("CivilizationRunner: Starting sequential campaign run (Phases 6-10)")

    results =
      Enum.reduce_while(@campaigns, [], fn {phase_id, {mod, fun, args}}, acc ->
        Logger.info("CivilizationRunner: Running #{phase_id} (#{inspect(mod)})")

        {result, dur} = run_campaign_timed(mod, fun, args)
        emit(:phase_run, phase_id, dur, match?({:ok, _}, result))

        case result do
          {:ok, result} ->
            CampaignIntegration.route_result(phase_id, %{
              status: :completed,
              result: result,
              completed_at: DateTime.utc_now()
            })
            {:cont, [{phase_id, :ok, result} | acc]}

          {:error, reason} ->
            Logger.error("CivilizationRunner: #{phase_id} failed: #{inspect(reason)}")
            CampaignIntegration.route_result(phase_id, %{
              status: :failed,
              error: inspect(reason),
              failed_at: DateTime.utc_now()
            })
            {:halt, [{phase_id, :error, reason} | acc]}
        end
      end)

    {:ok, Enum.reverse(results)}
  end

  @doc "Runs a single campaign by phase ID."
  def run_phase(phase_id) do
    case List.keyfind(@campaigns, phase_id, 0) do
      {_id, {mod, fun, args}} ->
        Logger.info("CivilizationRunner: Running single phase #{phase_id}")

        {result, dur} = run_campaign_timed(mod, fun, args)
        emit(:phase_run, phase_id, dur, match?({:ok, _}, result))

        case result do
          {:ok, result} ->
            CampaignIntegration.route_result(phase_id, %{
              status: :completed,
              result: result,
              completed_at: DateTime.utc_now()
            })
            {:ok, result}

          {:error, reason} ->
            CampaignIntegration.route_result(phase_id, %{
              status: :failed,
              error: inspect(reason),
              failed_at: DateTime.utc_now()
            })
            {:error, reason}
        end

      nil ->
        {:error, :unknown_phase}
    end
  end

  @doc "Validates that all campaign modules are loadable."
  def validate_readiness do
    checks =
      Enum.map(@campaigns, fn {phase_id, {mod, fun, _args}} ->
        mod_loaded = Code.ensure_loaded?(mod)
        fun_exported = mod_loaded && function_exported?(mod, fun, 0)
        campaign_loaded = mod_loaded && fun_exported

        unless campaign_loaded do
          Logger.warning("CivilizationRunner: #{phase_id} (#{inspect(mod)}.#{fun}/0) not available")
        end

        {phase_id, %{
          module_loaded: mod_loaded,
          function_exported: fun_exported,
          ready: campaign_loaded
        }}
      end)

    passed = Enum.count(checks, fn {_id, c} -> c.ready end)
    total = length(checks)

    %{
      ready: passed == total,
      passed: passed,
      total: total,
      checks: checks
    }
  end

  defp run_campaign_timed(mod, fun, args) do
    start = System.monotonic_time(:millisecond)
    result = run_campaign(mod, fun, args)
    dur = System.monotonic_time(:millisecond) - start
    {result, dur}
  end

  defp run_campaign(mod, fun, args) do
    try do
      case apply(mod, fun, args) do
        {:ok, result} -> {:ok, result}
        {:error, reason} -> {:error, reason}
        result -> {:ok, result}
      end
    rescue
      e ->
        Logger.error("CivilizationRunner: Campaign #{inspect(mod)}.#{fun} raised: #{inspect(e)}")
        {:error, e}
    catch
      :exit, reason -> {:error, {:exit, reason}}
    end
  end
end
