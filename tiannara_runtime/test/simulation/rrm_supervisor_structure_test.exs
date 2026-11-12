defmodule Tiannara.Simulation.RRMSupervisorStructureTest do
  @moduledoc """
  Structural validation of the runtime-metamorphosis supervision tree.

  The RRM supervisor previously listed three stateless service modules as
  children. Those modules export neither `child_spec/1` nor `start_link/1`, so
  `Supervisor.init/2` could not build the child specs and the supervisor could
  not start. These tests pin that every supervised child is a startable
  process and that the service modules remain directly callable.
  """
  use ExUnit.Case, async: true

  alias Tiannara.Phase18.RRM.{AdaptationController, MetaIRGenerator, Metrics}

  @supervised [
    Tiannara.Phase18.RRM.RuleEvolution,
    Tiannara.Phase18.RRM.EquivalenceVerifier,
    Tiannara.Phase18.RRM.FallbackRouter,
    Tiannara.Phase18.RRM.NativeBridge
  ]

  @service_modules [AdaptationController, MetaIRGenerator, Metrics]

  test "every supervised child exports a usable child spec" do
    for module <- @supervised do
      assert Code.ensure_loaded?(module), "#{inspect(module)} could not be loaded"

      assert function_exported?(module, :child_spec, 1),
             "#{inspect(module)} does not export child_spec/1"

      spec = module.child_spec([])

      assert is_map(spec)
      assert Map.get(spec, :id) == module

      case Map.get(spec, :start) do
        {m, :start_link, args} when is_list(args) ->
          assert m == module

        other ->
          flunk("unexpected start spec: #{inspect(other)}")
      end
    end
  end

  test "every supervised child exports start_link/1" do
    for module <- @supervised do
      assert Code.ensure_loaded?(module), "#{inspect(module)} could not be loaded"

      assert function_exported?(module, :start_link, 1),
             "#{inspect(module)} does not export start_link/1"
    end
  end

  test "the service modules are not supervised and remain directly callable" do
    for module <- @service_modules do
      refute function_exported?(module, :child_spec, 1),
             "#{inspect(module)} must not be supervised: it is a service module"
    end

    assert is_number(AdaptationController.compute_metamorphosis_score(0.8, 0.9, 0.1, 0.1))
    assert is_map(MetaIRGenerator.wrap_with_meta(%{nodes: [1, 2], edges: [1]}, :cpu))
    assert is_list(Metrics.metrics())
  end
end
