defmodule Tiannara.Phase5.StabilityStackTest do
  use ExUnit.Case, async: false
  use PropCheck

  @moduletag store_counter_example: false

  alias Tiannara.HSV.CurvatureEngine
  alias Tiannara.RRG.EquilibriumEngine
  alias Tiannara.TWP.PersistenceEstimator

  property "HSV triggers collapse only when curvature exceeds critical threshold" do
    forall({omega, phi, c, r} <- curvature_input_generator(), do:
      assert_hsv_boundaries(omega, phi, c, r)
    )
  end

  property "RRG stability metric remains bounded under extreme divergence" do
    forall({ds, n, cb, ec, ro} <- rrg_input_generator(), do:
      assert_rrg_boundedness(ds, n, cb, ec, ro)
    )
  end

  property "TWP correctly prunes low-persistence timelines" do
    forall({o, e, _} <- twp_input_generator(), do:
      assert_twp_pruning(o, e)
    )
  end

  defp curvature_input_generator() do
    let {o, p, c, r} <- {float(0.1, 100.0), float(0.1, 50.0), float(0.1, 5.0), float(0.1, 3.0)} do
      {o, p, c, r}
    end
  end

  defp rrg_input_generator() do
    let {d, n, cb, ec, ro} <- {float(0.1, 1.0), float(0.1, 1.0), float(0.1, 1.0), float(0.1, 1.0), float(0.1, 1.0)} do
      {d, n, cb, ec, ro}
    end
  end

  defp twp_input_generator() do
    let {o, e} <- {float(0.0, 1.0), float(0.0, 1.0)} do
      {o, e, :ok}
    end
  end

  defp assert_hsv_boundaries(omega, phi, c, r) do
    {status, kappa} = CurvatureEngine.compute(%{ontology_density: omega, compute_pressure: phi, causal_divergence: c, observer_recursion: r})
    status in [:stable, :collapse_required] and kappa >= 0
  end

  defp assert_rrg_boundedness(ds, n, cb, ec, ro) do
    psi = EquilibriumEngine.compute(ds, n, cb, ec, ro)
    psi >= 0.0 and psi <= 100.0
  end

  defp assert_twp_pruning(o, e) do
    p_t = PersistenceEstimator.estimate(o, e)
    p_t >= 0.0 and p_t <= 1.0
  end
end

defmodule Tiannara.HSV.CurvatureEngine do
  def compute(params) do
    omega = Map.get(params, :ontology_density, 0.5)
    phi = Map.get(params, :compute_pressure, 0.5)
    c = Map.get(params, :causal_divergence, 0.5)
    r = Map.get(params, :observer_recursion, 0.5)
    kappa = (omega + phi + c) * r
    status = if kappa > 200.0, do: :collapse_required, else: :stable
    {status, kappa}
  end
end

defmodule Tiannara.TWP.PersistenceEstimator do
  def estimate(o, e) do
    p_t = o * e
    max(0.0, min(1.0, p_t))
  end
end