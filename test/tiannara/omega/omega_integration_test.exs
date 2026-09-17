defmodule Tiannara.Omega.OmegaIntegrationTest do
  use ExUnit.Case, async: false

  alias Tiannara.Omega.{AgencyLoop, RuntimeHealthAggregator, ConstitutionalComplianceMonitor, Observatory}

  describe "boot validation" do
    test "all omega subsystems are running" do
      assert Process.whereis(Tiannara.Omega.AgencyLoop) != nil
      assert Process.whereis(Tiannara.Omega.RuntimeHealthAggregator) != nil
      assert Process.whereis(Tiannara.Omega.ConstitutionalComplianceMonitor) != nil
      assert Process.whereis(Tiannara.Omega.Observatory) != nil
    end

    test "runtime health aggregator returns health" do
      health = RuntimeHealthAggregator.health()
      assert health.status in [:healthy, :partial, :degraded]
      assert health.subsystems_total >= 1
    end
  end

  describe "agency loop" do
    test "advances through phases" do
      initial_phase = AgencyLoop.current_phase()
      assert initial_phase in [:observe, :analyze, :investigate, :communicate, :improve, :learn]

      AgencyLoop.advance()
      :timer.sleep(50)

      new_phase = AgencyLoop.current_phase()
      assert new_phase in [:observe, :analyze, :investigate, :communicate, :improve, :learn]
    end

    test "completes full loops" do
      for _ <- 1..6 do
        AgencyLoop.advance()
        :timer.sleep(20)
      end

      status = AgencyLoop.status()
      assert status.loops_completed >= 1
    end

    test "status returns structured data" do
      status = AgencyLoop.status()
      assert status.current_phase != nil
      assert is_integer(status.loops_completed)
      assert status.started_at != nil
      assert is_integer(status.uptime_seconds)
    end
  end

  describe "constitutional compliance" do
    test "compliance monitor status returns checks data" do
      status = ConstitutionalComplianceMonitor.status()
      assert is_map(status)
      assert is_integer(status.checks_performed)
    end

    test "compliance can be checked on demand" do
      result = ConstitutionalComplianceMonitor.check_now()
      assert is_map(result)
    end
  end

  describe "observatory" do
    test "returns dashboard with required sections" do
      dashboard = Observatory.dashboard()
      assert is_map(dashboard)
      assert Map.has_key?(dashboard, :overview)
      assert Map.has_key?(dashboard, :sentinel)
      assert Map.has_key?(dashboard, :research)
      assert Map.has_key?(dashboard, :interface)
      assert Map.has_key?(dashboard, :autonomy)
      assert Map.has_key?(dashboard, :cognitive_runtime)
      assert Map.has_key?(dashboard, :compliance)
      assert Map.has_key?(dashboard, :vm)
    end

    test "returns specific section" do
      overview = Observatory.section(:overview)
      assert is_map(overview)
    end
  end

  describe "omega runtime facade" do
    test "returns aggregated status" do
      status = Tiannara.Omega.OmegaRuntime.status()
      assert is_map(status)
    end

    test "returns health" do
      health = Tiannara.Omega.OmegaRuntime.health()
      assert health.status in [:healthy, :partial, :degraded]
    end

    test "returns current phase" do
      phase = Tiannara.Omega.OmegaRuntime.current_phase()
      assert phase in [:observe, :analyze, :investigate, :communicate, :improve, :learn]
    end

    test "returns compliance" do
      compliance = Tiannara.Omega.OmegaRuntime.compliance()
      assert is_map(compliance)
    end

    test "returns observatory data" do
      obs = Tiannara.Omega.OmegaRuntime.observatory()
      assert is_map(obs)
      assert Map.has_key?(obs, :overview)
    end
  end

  describe "runtime health aggregator" do
    test "full_status contains all subsystems" do
      status = RuntimeHealthAggregator.full_status()
      assert Map.has_key?(status, :executive)
      assert Map.has_key?(status, :sentinel)
      assert Map.has_key?(status, :research)
      assert Map.has_key?(status, :interface)
      assert Map.has_key?(status, :autonomy)
      assert Map.has_key?(status, :ecr)
      assert Map.has_key?(status, :agency_loop)
      assert Map.has_key?(status, :vm)
    end
  end
end
