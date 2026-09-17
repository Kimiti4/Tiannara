defmodule Tiannara.ASC.Civilization.ForecastTest do
  use ExUnit.Case, async: false

  setup do
    for mod <- [Tiannara.ASC.Civilization.LongTermForecastEngine, Tiannara.ASC.Civilization.WorldModel] do
      case mod.start_link([]) do
        {:ok, _} -> :ok
        {:error, {:already_started, _}} -> :ok
      end
    end
    :ok
  end

  test "generates multi-decade forecast" do
    world_state = Tiannara.ASC.Civilization.WorldModel.current_state()
    {:ok, forecast} = Tiannara.ASC.Civilization.LongTermForecastEngine.forecast(world_state, %{})

    assert forecast.horizon_years == 100
    assert length(forecast.projections) == 4
    assert forecast.confidence >= 0.0 and forecast.confidence <= 1.0
  end

  test "uncertainty increases with time horizon" do
    world_state = Tiannara.ASC.Civilization.WorldModel.current_state()
    {:ok, forecast} = Tiannara.ASC.Civilization.LongTermForecastEngine.forecast(world_state, %{})

    uncertainties = Enum.map(forecast.projections, & &1.uncertainty)
    assert uncertainties == Enum.sort(uncertainties)
  end

  test "world model projects domain values" do
    projection = Tiannara.ASC.Civilization.WorldModel.project(:technology, 50)

    assert projection.domain == :technology
    assert projection.projected >= projection.current
    assert projection.uncertainty > 0
  end
end
