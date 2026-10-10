defmodule TiannaraOS.Governance.Certification.LaboratoryFailClosedTest do
  use ExUnit.Case, async: true

  alias TiannaraOS.Governance.Certification.Laboratory

  test "GC-001 refuses to certify unrelated global-ledger replay as isolated history replay" do
    assert {:error, %{campaign: :gc_001_replay, certification_status: :not_certifiable}} =
             Laboratory.execute_campaign(:gc_001_replay, sample_count: 1)
  end

  test "GC-002 refuses certification until a canonical authority executor exists" do
    assert {:error, %{campaign: :gc_002_authority_fuzzing, certification_status: :not_certifiable}} =
             Laboratory.execute_campaign(:gc_002_authority_fuzzing)
  end

  test "GC-009 refuses to call repeated snapshots mutation stability" do
    assert {:error, %{campaign: :gc_009_entropy_stability, certification_status: :not_certifiable}} =
             Laboratory.execute_campaign(:gc_009_entropy_stability)
  end

  test "GC-010 refuses to call repeated evaluations mutation stability" do
    assert {:error, %{campaign: :gc_010_fitness_stability, certification_status: :not_certifiable}} =
             Laboratory.execute_campaign(:gc_010_fitness_stability)
  end

  test "GC-012 refuses to certify a synthetic evolution simulation as runtime evolution" do
    assert {:error, %{campaign: :gc_012_long_horizon_evolution, certification_status: :not_certifiable}} =
             Laboratory.execute_campaign(:gc_012_long_horizon_evolution)
  end
end
