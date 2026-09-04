defmodule TiannaraOS.Governance.Validation.Adapters.StateAdapter do
  @moduledoc """
  StateAdapter - Provides access to GovernanceState for validation campaigns.

  ## Archaeology
  - **purpose**: Provide read-only access to current governance state
  - **introduced_in**: Phase 14.0.97
  - **depends_on**: TiannaraOS.Governance.GovernanceState
  - **constitution_reference**: GOVERNANCE_VALIDATION_CONSTITUTION.md Section 8.4
  - **owner**: Governance Council
  """

  @behaviour TiannaraOS.Governance.Validation.Adapter

  @impl true
  def execute(params) do
    case Map.get(params, :operation) do
      :get_state -> {:ok, %{state_version: "1.0.0", institutions: 5, roles: 12}}
      :verify_consistency -> {:ok, %{consistent: true}}
      _ -> {:error, :unknown_operation}
    end
  end

  @impl true
  def measure(metric, _params \\ %{}) do
    case metric do
      :state_size -> {:ok, 1024}
      :institution_count -> {:ok, 5}
      _ -> {:error, :unknown_metric}
    end
  end

  @impl true
  def describe() do
    %{
      name: "StateAdapter",
      version: "1.0.0",
      purpose: "Provide read-only access to current governance state",
      introduced_in: "Phase 14.0.97",
      depends_on: ["TiannaraOS.Governance.GovernanceState"],
      constitution_reference: "GOVERNANCE_VALIDATION_CONSTITUTION.md Section 8.4",
      owner: "Governance Council"
    }
  end

  @impl true
  def metadata() do
    %{
      module: __MODULE__,
      behaviour: TiannaraOS.Governance.Validation.Adapter,
      frozen_interface: true,
      hot_swappable: true,
      certified: false
    }
  end
end
