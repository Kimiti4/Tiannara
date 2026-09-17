defmodule Tiannara.Discovery.Steps.ProviderContractTest do
  @moduledoc """
  Certifies the producer/consumer wiring by OBSERVABLE, not by assumption:

    1. CapabilityGraph resolves each capability to the real step module
       (so the unguarded find_optimal_provider dispatch path can't :noproc
       or :no_provider).
    2. Every step module exports the exact callbacks the WorkflowEngine
       invokes (required_capability/0, execute/2, step_type/0, compensate/3).
    3. Topics — the single source of truth — is non-empty and unique.

  If the ProviderSeeder's registration is wrong, (1) fails here — loudly, in
  the suite — instead of at boot or, worse, at step 1 of the soak.
  """
  use ExUnit.Case, async: false

  alias Tiannara.Discovery.{Step, Topics}
  alias Tiannara.Discovery.Steps.{ExperimentStep, ValidationStep, ProviderSeeder}

  setup do
    case Tiannara.CEL.Services.CapabilityGraph.start_link([]) do
      {:ok, _} -> :ok
      {:error, {:already_started, _}} -> :ok
    end

    _ = ProviderSeeder.register()
    :ok
  end

  test "every declared provider resolves via find_optimal_provider to the real module" do
    cg = Tiannara.CEL.Services.CapabilityGraph

    for {capability, module} <- ProviderSeeder.providers() do
      assert {:ok, sub_id, score} = cg.find_optimal_provider(capability),
             "capability #{inspect(capability)} must resolve — registration failed"

      assert is_atom(sub_id) and is_number(score)

      assert ProviderSeeder.provider_module(capability) == module,
             "capability #{inspect(capability)} must map to #{inspect(module)}"
    end
  end

  test "the provider subsystem is the seeder's declared one" do
    cg = Tiannara.CEL.Services.CapabilityGraph
    subsystem = ProviderSeeder.subsystem()

    for {capability, _module} <- ProviderSeeder.providers() do
      assert {:ok, ^subsystem, _score} = cg.find_optimal_provider(capability)
    end
  end

  test "each step exports the callbacks the engine invokes" do
    for mod <- [ExperimentStep, ValidationStep] do
      functions = mod.__info__(:functions) |> Enum.map(&elem(&1, 0))

      for fun <- [:required_capability, :execute, :step_type, :compensate] do
        assert fun in functions, "#{inspect(mod)} must export #{fun}"
      end

      assert is_atom(mod.required_capability())
      assert is_atom(mod.step_type())
    end
  end

  test "shared measurement helpers are pure and bounded" do
    assert Step.confidence_from_divergence(3.4, 1.0) >= 0.5
    assert Step.confidence_from_divergence(0.0, 1.0) == 0.0
    assert Step.confidence_from_divergence(nil, 1.0) == 0.0
    assert Step.confidence_from_divergence(1.0, 0.0) == 0.0
    assert Step.decisive?(:confirmed)
    assert Step.decisive?(:refuted)
    refute Step.decisive?(:inconclusive)
  end

  test "Topics single-source-of-truth is non-empty and unique" do
    topics = Topics.all()
    refute topics == []
    assert topics == Enum.uniq(topics)
    assert Topics.evidence_routed() in topics
    assert Topics.experiment_completed() in topics
    assert Topics.discovery_completed() in topics
  end
end
