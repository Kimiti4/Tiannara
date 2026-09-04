defmodule TiannaraOS.Governance.Validation.Adapter do
  @moduledoc """
  Adapter - Frozen behaviour contract for all validation adapters.

  This module defines the interface that ALL validation adapters must implement.
  The interface is frozen as of Phase 14.0.96 and cannot change without constitutional amendment.

  ## Required Callbacks

  Every adapter must implement:
  - `execute/1` - Execute the adapter's primary operation
  - `measure/2` - Measure a specific metric
  - `describe/0` - Return adapter metadata (archaeology)
  - `metadata/0` - Return runtime metadata

  ## Archaeology Requirements

  Every adapter's `describe/0` must return:
  - `purpose` - Why this adapter exists
  - `introduced_in` - Phase/version when added
  - `depends_on` - List of dependencies
  - `constitution_reference` - Constitutional section it implements
  - `owner` - Responsible institution

  ## Usage

      defmodule MyAdapter do
        @behaviour TiannaraOS.Governance.Validation.Adapter

        @impl true
        def execute(params), do: {:ok, result}

        @impl true
        def measure(metric, params \\ %{}), do: {:ok, value}

        @impl true
        def describe(), do: %{purpose: "...", ...}

        @impl true
        def metadata(), do: %{module: __MODULE__, ...}
      end
  """

  @type params :: map()
  @type metric :: atom()
  @type execution_result :: {:ok, any()} | {:error, term()}
  @type measurement_result :: {:ok, any()} | {:error, term()}
  @type description :: map()
  @type adapter_metadata :: map()

  @doc """
  Execute the adapter's primary operation.

  Parameters are adapter-specific but must be passed as a map.
  Returns {:ok, result} or {:error, reason}.
  """
  @callback execute(params()) :: execution_result()

  @doc """
  Measure a specific metric.

  The metric atom determines what to measure.
  Optional params can refine the measurement.
  Returns {:ok, value} or {:error, reason}.
  """
  @callback measure(metric(), params()) :: measurement_result()

  @doc """
  Return adapter metadata for archaeology.

  Must include:
  - purpose: String.t()
  - introduced_in: String.t()
  - depends_on: [String.t()]
  - constitution_reference: String.t()
  - owner: String.t()
  """
  @callback describe() :: description()

  @doc """
  Return runtime metadata about the adapter.

  Must include:
  - module: module()
  - behaviour: module()
  - frozen_interface: boolean()
  - hot_swappable: boolean()
  - certified: boolean()
  """
  @callback metadata() :: adapter_metadata()

  @optional_callbacks []
end
