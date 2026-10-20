defmodule TiannaraRuntime.Civilization.Economy.EconomyTest do
  use ExUnit.Case
  @moduletag :civilization
  @moduletag :economy

  alias TiannaraRuntime.Civilization.Economy.ScientificCapitalLedger
  alias TiannaraRuntime.Civilization.Economy.CapitalAllocator
  alias TiannaraRuntime.Civilization.Economy.PortfolioAllocator
  alias TiannaraRuntime.Civilization.Economy.InvestmentPlanner
  alias TiannaraRuntime.Civilization.Economy.ScientificMarket
  alias TiannaraRuntime.Civilization.Economy.EconomyReplay
  alias TiannaraRuntime.Civilization.Economy.EconomyArchaeology

  test "ledger record_transaction and verify" do
    {:ok, ledger} = ScientificCapitalLedger.initialize()
    {:ok, ledger} = ScientificCapitalLedger.record_transaction(ledger, :alice, :bob, 50, :grant)
    {:ok, from_bal} = ScientificCapitalLedger.get_balance(ledger, :alice)
    assert from_bal == -50
    {:ok, to_bal} = ScientificCapitalLedger.get_balance(ledger, :bob)
    assert to_bal == 50
    {:ok, verified} = ScientificCapitalLedger.verify(ledger)
    assert verified == false
  end

  test "allocator allocate and insufficient_funds" do
    {:ok, allocator} = CapitalAllocator.initialize(100)
    {:ok, allocator} = CapitalAllocator.allocate(allocator, "prog_1", 40, :research)
    assert allocator.allocations["prog_1"] == 40
    assert allocator.total == 60
    assert CapitalAllocator.allocate(allocator, "prog_2", 200, :expansion) == {:error, :insufficient_funds}
  end

  test "portfolio_allocator allocate and balance" do
    {:ok, allocator} = PortfolioAllocator.initialize([:physics, :biology, :mathematics])
    {:ok, allocator} = PortfolioAllocator.allocate(allocator, :physics, 100)
    {:ok, allocator} = PortfolioAllocator.allocate(allocator, :biology, 50)
    {:ok, balanced} = PortfolioAllocator.balance(allocator)
    doms = balanced.domains
    assert doms[:physics][:allocation] == 50
    assert doms[:biology][:allocation] == 50
    assert doms[:mathematics][:allocation] == 50
  end

  test "planner plan and project" do
    {:ok, planner} = InvestmentPlanner.initialize()
    {:ok, planner} = InvestmentPlanner.plan(planner, "prog_1", 100, 5, 1.5)
    {:ok, planner} = InvestmentPlanner.plan(planner, "prog_2", 200, 10, 2.0)
    {:ok, projected} = InvestmentPlanner.project(planner, 7)
    assert projected == 100 * 1.5
    {:ok, metrics} = InvestmentPlanner.metrics(planner)
    assert metrics.program_count == 2
  end

  test "market list_asset and exchange" do
    {:ok, market} = ScientificMarket.initialize()
    {:ok, market} = ScientificMarket.list_asset(market, "asset_1", :patent, 1000)
    {:ok, market} = ScientificMarket.exchange(market, :alice, :bob, "asset_1")
    {:ok, metrics} = ScientificMarket.metrics(market)
    assert metrics.assets_listed == 1
    assert metrics.exchanges == 1
    assert ScientificMarket.exchange(market, :alice, :bob, "nonexistent") == {:error, :not_found}
  end

  test "replay record and verify" do
    {:ok, ledger} = ScientificCapitalLedger.initialize()
    {:ok, allocator} = CapitalAllocator.initialize(100)
    {:ok, planner} = InvestmentPlanner.initialize()
    {:ok, _} = ScientificCapitalLedger.record_transaction(ledger, :a, :b, 30, :grant)
    {:ok, _} = CapitalAllocator.allocate(allocator, "p1", 40, :research)
    {:ok, planner} = InvestmentPlanner.plan(planner, "p1", 50, 3, 1.2)
    {:ok, replay} = EconomyReplay.record(ledger, allocator, planner)
    assert is_map(replay)
    assert replay.timestamp > 0
    {:ok, :verified} = EconomyReplay.verify(replay, ledger, allocator, planner)
    bad_planner = %{planner | schedule: []}
    assert EconomyReplay.verify(replay, ledger, allocator, bad_planner) == {:error, :mismatch}
  end

  test "archaeology record and explain" do
    {:ok, ledger} = ScientificCapitalLedger.initialize()
    {:ok, allocator} = CapitalAllocator.initialize(500)
    {:ok, _} = ScientificCapitalLedger.record_transaction(ledger, :x, :y, 100, :investment)
    {:ok, allocator} = CapitalAllocator.allocate(allocator, "prog_a", 200, :strategic)
    {:ok, archaeology} = EconomyArchaeology.record(ledger, allocator, "Phase19")
    {:ok, explanation} = EconomyArchaeology.explain(archaeology)
    assert String.contains?(explanation, "Phase19")
    {:ok, lineage} = EconomyArchaeology.get_lineage(archaeology)
    assert lineage.programs == ["prog_a"]
  end
end
