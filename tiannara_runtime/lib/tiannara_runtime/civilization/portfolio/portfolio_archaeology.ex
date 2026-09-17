defmodule TiannaraRuntime.Civilization.Portfolio.PortfolioArchaeology do
  def record(manager, registry, origin) do
    {:ok, %{manager: manager, registry: registry, origin: origin, lineage: []}}
  end

  def explain(archaeology) do
    portfolio_count = length(Map.get(archaeology, :manager, %{}) |> Map.get(:portfolios, []))
    program_count = map_size(Map.get(archaeology, :registry, %{}) |> Map.get(:programs, %{}))
    narrative = "Portfolio archaeology from #{Map.get(archaeology, :origin)}: #{portfolio_count} portfolios, #{program_count} programs"
    {:ok, narrative}
  end

  def get_lineage(archaeology) do
    {:ok, Map.get(archaeology, :lineage, [])}
  end
end
