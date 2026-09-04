defmodule TiannaraOS.Governance.Validation.AdapterRegistry do
  @moduledoc """
  AdapterRegistry - Manages adapter implementations with hot-swapping support.

  This module provides indirection between campaigns and adapter implementations,
  allowing adapters to be swapped without changing campaign specifications.

  Campaigns reference adapters by name (e.g., :ledger_adapter), and this registry
  resolves that name to the actual implementation module.

  ## Usage

      AdapterRegistry.register(:replay_adapter, ReplayAdapterV1)
      {:ok, adapter_module} = AdapterRegistry.resolve(:replay_adapter)

  ## Hot-Swapping

  New adapter versions can be registered without stopping the system:

      AdapterRegistry.register(:replay_adapter, ReplayAdapterV2)
  """

  use GenServer

  @type adapter_name :: atom()
  @type adapter_module :: module()

  # Client API

  @doc """
  Start the adapter registry.
  """
  @spec start_link(keyword()) :: GenServer.on_start()
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc """
  Register an adapter implementation.

  Returns :ok on success, {:error, reason} if adapter is invalid.
  """
  @spec register(adapter_name(), adapter_module()) :: :ok | {:error, term()}
  def register(name, module) do
    GenServer.call(__MODULE__, {:register, name, module})
  end

  @doc """
  Resolve adapter name to implementation module.

  Returns {:ok, module} or {:error, :not_found}.
  """
  @spec resolve(adapter_name()) :: {:ok, adapter_module()} | {:error, :not_found}
  def resolve(name) do
    GenServer.call(__MODULE__, {:resolve, name})
  end

  @doc """
  List all registered adapters.
  """
  @spec list_adapters() :: [{adapter_name(), adapter_module()}]
  def list_adapters() do
    GenServer.call(__MODULE__, :list_adapters)
  end

  @doc """
  Unregister an adapter (for hot-swapping).
  """
  @spec unregister(adapter_name()) :: :ok | {:error, :not_found}
  def unregister(name) do
    GenServer.call(__MODULE__, {:unregister, name})
  end

  # Server callbacks

  @impl true
  def init(_opts) do
    # Initialize with default adapters
    initial_adapters = initialize_default_adapters()
    {:ok, %{adapters: initial_adapters}}
  end

  @impl true
  def handle_call({:register, name, module}, _from, state) do
    # Validate module implements required behaviour
    case validate_adapter(module) do
      :valid ->
        new_adapters = Map.put(state.adapters, name, module)
        {:reply, :ok, %{state | adapters: new_adapters}}
      {:invalid, reason} ->
        {:reply, {:error, reason}, state}
    end
  end

  @impl true
  def handle_call({:resolve, name}, _from, state) do
    case Map.get(state.adapters, name) do
      nil -> {:reply, {:error, :not_found}, state}
      module -> {:reply, {:ok, module}, state}
    end
  end

  @impl true
  def handle_call(:list_adapters, _from, state) do
    {:reply, Map.to_list(state.adapters), state}
  end

  @impl true
  def handle_call({:unregister, name}, _from, state) do
    case Map.pop(state.adapters, name) do
      {nil, _} -> {:reply, {:error, :not_found}, state}
      {_module, new_adapters} -> {:reply, :ok, %{state | adapters: new_adapters}}
    end
  end

  # Private helpers

  defp initialize_default_adapters() do
    # Register default adapter implementations
    # All adapters implement TiannaraOS.Governance.Validation.Adapter behaviour
    %{
      ledger_adapter: TiannaraOS.Governance.Validation.Adapters.LedgerAdapter,
      replay_adapter: TiannaraOS.Governance.Validation.Adapters.ReplayAdapter,
      state_adapter: TiannaraOS.Governance.Validation.Adapters.StateAdapter,
      graph_adapter: TiannaraOS.Governance.Validation.Adapters.GraphAdapter,
      certificate_adapter: TiannaraOS.Governance.Validation.Adapters.CertificateAdapter,
      fingerprint_adapter: TiannaraOS.Governance.Validation.Adapters.FingerprintAdapter,
      fitness_adapter: TiannaraOS.Governance.Validation.Adapters.FitnessAdapter,
      entropy_adapter: TiannaraOS.Governance.Validation.Adapters.EntropyAdapter,
      cost_adapter: TiannaraOS.Governance.Validation.Adapters.CostAdapter,
      archaeology_adapter: TiannaraOS.Governance.Validation.Adapters.ArchaeologyAdapter,
      campaign_01_adapter: TiannaraOS.Governance.Certification.Campaigns.Campaign01,
      campaign_02_adapter: TiannaraOS.Governance.Certification.Campaigns.Campaign02,
      campaign_03_adapter: TiannaraOS.Governance.Certification.Campaigns.Campaign03,
      campaign_04_adapter: TiannaraOS.Governance.Certification.Campaigns.Campaign04,
      campaign_05_adapter: TiannaraOS.Governance.Certification.Campaigns.Campaign05,
      campaign_06_adapter: TiannaraOS.Governance.Certification.Campaigns.Campaign06,
      campaign_07_adapter: TiannaraOS.Governance.Certification.Campaigns.Campaign07,
      campaign_08_adapter: TiannaraOS.Governance.Certification.Campaigns.Campaign08,
      campaign_09_adapter: TiannaraOS.Governance.Certification.Campaigns.Campaign09,
      campaign_10_adapter: TiannaraOS.Governance.Certification.Campaigns.Campaign10,
      campaign_11_adapter: TiannaraOS.Governance.Certification.Campaigns.Campaign11,
      campaign_12_adapter: TiannaraOS.Governance.Certification.Campaigns.Campaign12,
      campaign_13_adapter: TiannaraOS.Governance.Certification.Campaigns.Campaign13,
      campaign_14_adapter: TiannaraOS.Governance.Certification.Campaigns.Campaign14,
      campaign_15_adapter: TiannaraOS.Governance.Certification.Campaigns.Campaign15,
      campaign_16_adapter: TiannaraOS.Governance.Certification.Campaigns.Campaign16,
      campaign_17_adapter: TiannaraOS.Governance.Certification.Campaigns.Campaign17,
      campaign_18_adapter: TiannaraOS.Governance.Certification.Campaigns.Campaign18,
      campaign_19_adapter: TiannaraOS.Governance.Certification.Campaigns.Campaign19,
      campaign_20_adapter: TiannaraOS.Governance.Certification.Campaigns.Campaign20,
      campaign_21_adapter: TiannaraOS.Governance.Certification.Campaigns.Campaign21,
      campaign_22_adapter: TiannaraOS.Governance.Certification.Campaigns.Campaign22,
      campaign_23_adapter: TiannaraOS.Governance.Certification.Campaigns.Campaign23,
      campaign_24_adapter: TiannaraOS.Governance.Certification.Campaigns.Campaign24,
      campaign_25_adapter: TiannaraOS.Governance.Certification.Campaigns.Campaign25,
      campaign_26_adapter: TiannaraOS.Governance.Certification.Campaigns.Campaign26,
      campaign_27_adapter: TiannaraOS.Governance.Certification.Campaigns.Campaign27,
      campaign_28_adapter: TiannaraOS.Governance.Certification.Campaigns.Campaign28,
      campaign_29_adapter: TiannaraOS.Governance.Certification.Campaigns.Campaign29,
      campaign_30_adapter: TiannaraOS.Governance.Certification.Campaigns.Campaign30
    }
  end

  defp validate_adapter(module) do
    # Check if module exists and exports required functions
    # In production: check @behaviour compliance
    if Code.ensure_loaded?(module) do
      :valid
    else
      {:invalid, "module #{inspect(module)} not loaded"}
    end
  end
end
