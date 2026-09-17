defmodule Tiannara.ASC.Engineering.ValidationTest do
  use ExUnit.Case, async: false

  alias Tiannara.ASC.Engineering.ValidationEngine

  setup do
    case ValidationEngine.start_link([]) do
      {:ok, _} -> :ok
      {:error, {:already_started, _}} -> :ok
    end
    :ok
  end

  test "validates a complete design" do
    design = %{
      id: "complete_design",
      architecture: %{pattern: :layered},
      components: [%{id: "core", name: "Core"}],
      interfaces: [%{name: :execute}],
      constraints: %{max_latency_ms: 500, safety_critical: true},
      verification_plan: %{safety_checks: true, unit_tests: true}
    }

    {:ok, report} = ValidationEngine.validate(design)

    assert report.passed == true
    assert report.score > 0.7
    assert length(report.checks) == 5
  end

  test "flags incomplete design" do
    design = %{id: "incomplete"}

    {:ok, report} = ValidationEngine.validate(design)

    assert report.passed == false
    assert report.score < 0.5
  end

  test "flags safety-critical design without safety checks" do
    design = %{
      id: "unsafe_design",
      architecture: %{pattern: :monolithic},
      components: [%{id: "core"}],
      interfaces: [],
      constraints: %{safety_critical: true},
      verification_plan: %{safety_checks: false}
    }

    {:ok, report} = ValidationEngine.validate(design)

    safety_check = Enum.find(report.checks, &(&1.name == :safety))
    assert safety_check.passed == false
  end
end
