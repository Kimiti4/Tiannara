defmodule Tiannara.Topology.ACF.LawManager do
  @moduledoc """
  Conservation Law Manager for ACF.

  Manages the definition, modification, and lifecycle of conservation laws.
  """

  use GenServer
  require Logger

  # Client API
  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def define_law(law_id, law_definition, opts \\ []) do
    GenServer.call(__MODULE__, {:define_law, law_id, law_definition, opts})
  end

  def modify_law(law_id, modifications) do
    GenServer.call(__MODULE__, {:modify_law, law_id, modifications})
  end

  def disable_law(law_id) do
    GenServer.call(__MODULE__, {:disable_law, law_id})
  end

  def enable_law(law_id) do
    GenServer.call(__MODULE__, {:enable_law, law_id})
  end

  def delete_law(law_id) do
    GenServer.call(__MODULE__, {:delete_law, law_id})
  end

  def get_law(law_id) do
    GenServer.call(__MODULE__, {:get_law, law_id})
  end

  def list_laws() do
    GenServer.call(__MODULE__, :list_laws)
  end

  def get_law_statistics() do
    GenServer.call(__MODULE__, :get_law_statistics)
  end

  def validate_law_definition(law_definition) do
    GenServer.call(__MODULE__, {:validate_law_definition, law_definition})
  end

  # Server callbacks
  @impl true
  def init(_opts) do
    reset_named_table(:conservation_laws, [
      :set,
      :public,
      :named_table,
      {:write_concurrency, true},
      {:read_concurrency, true}
    ])

    reset_named_table(:law_history, [
      :bag,
      :public,
      :named_table,
      {:write_concurrency, true}
    ])

    # Initialize default laws
    initialize_default_laws()

    Logger.info("Conservation Law Manager initialized")
    {:ok, %{}}
  end

  defp reset_named_table(name, options) do
    case :ets.whereis(name) do
      :undefined ->
        :ets.new(name, options)

      _tid ->
        :ets.delete(name)
        :ets.new(name, options)
    end
  end

  @impl true
  def handle_call({:define_law, law_id, law_definition, opts}, _from, state) do
    # Validate law definition
    case do_validate_law_definition(law_definition) do
      :ok ->
        # Check if law already exists
        case :ets.lookup(:conservation_laws, law_id) do
          [] ->
            # Create new law
            law_data = create_law_data(law_id, law_definition, opts)
            :ets.insert(:conservation_laws, {law_id, law_data})
            
            # Record law creation in history
            record_law_history(law_id, :created, law_definition)
            
            Logger.info("Defined conservation law #{law_id}")
            
            {:reply, :ok, state}
            
          [{^law_id, _}] ->
            Logger.warning("Conservation law #{law_id} already exists")
            {:reply, {:error, :law_already_exists}, state}
        end
        
      {:error, reason} ->
        Logger.error("Invalid law definition: #{reason}")
        {:reply, {:error, reason}, state}
    end
  end

  @impl true
  def handle_call({:modify_law, law_id, modifications}, _from, state) do
    # Check if law exists
    case :ets.lookup(:conservation_laws, law_id) do
      [{^law_id, law_data}] ->
        # Validate modifications
        case validate_modifications(law_data, modifications) do
          :ok ->
            # Apply modifications
            updated_law = apply_modifications(law_data, modifications)
            :ets.insert(:conservation_laws, {law_id, updated_law})
            
            # Record modification in history
            record_law_history(law_id, :modified, modifications)
            
            Logger.info("Modified conservation law #{law_id}")
            
            {:reply, :ok, state}
            
          {:error, reason} ->
            Logger.error("Invalid modifications for law #{law_id}: #{reason}")
            {:reply, {:error, reason}, state}
        end
        
      [] ->
        Logger.warning("Conservation law #{law_id} not found")
        {:reply, {:error, :law_not_found}, state}
    end
  end

  @impl true
  def handle_call({:disable_law, law_id}, _from, state) do
    case :ets.lookup(:conservation_laws, law_id) do
      [{^law_id, law_data}] ->
        updated_law = %{law_data | enabled: false, updated_at: System.system_time(:millisecond)}
        :ets.insert(:conservation_laws, {law_id, updated_law})
        
        record_law_history(law_id, :disabled, %{})
        
        Logger.info("Disabled conservation law #{law_id}")
        
        {:reply, :ok, state}
        
      [] ->
        Logger.warning("Conservation law #{law_id} not found")
        {:reply, {:error, :law_not_found}, state}
    end
  end

  @impl true
  def handle_call({:enable_law, law_id}, _from, state) do
    case :ets.lookup(:conservation_laws, law_id) do
      [{^law_id, law_data}] ->
        updated_law = %{law_data | enabled: true, updated_at: System.system_time(:millisecond)}
        :ets.insert(:conservation_laws, {law_id, updated_law})
        
        record_law_history(law_id, :enabled, %{})
        
        Logger.info("Enabled conservation law #{law_id}")
        
        {:reply, :ok, state}
        
      [] ->
        Logger.warning("Conservation law #{law_id} not found")
        {:reply, {:error, :law_not_found}, state}
    end
  end

  @impl true
  def handle_call({:delete_law, law_id}, _from, state) do
    case :ets.lookup(:conservation_laws, law_id) do
      [{^law_id, law_data}] ->
        :ets.delete(:conservation_laws, law_id)
        
        record_law_history(law_id, :deleted, %{})
        
        Logger.info("Deleted conservation law #{law_id}")
        
        {:reply, :ok, state}
        
      [] ->
        Logger.warning("Conservation law #{law_id} not found")
        {:reply, {:error, :law_not_found}, state}
    end
  end

  @impl true
  def handle_call({:get_law, law_id}, _from, state) do
    case :ets.lookup(:conservation_laws, law_id) do
      [{^law_id, law_data}] ->
        {:reply, {:ok, law_data}, state}
      [] ->
        {:reply, {:error, :law_not_found}, state}
    end
  end

  @impl true
  def handle_call(:list_laws, _from, state) do
    laws = :ets.tab2list(:conservation_laws)
    |> Enum.map(fn {law_id, law_data} ->
      %{id: law_id, data: law_data}
    end)
    
    {:reply, {:ok, laws}, state}
  end

  @impl true
  def handle_call(:get_law_statistics, _from, state) do
    laws = :ets.tab2list(:conservation_laws)
    
    statistics = %{
      total_laws: length(laws),
      enabled_laws: Enum.count(laws, fn {_, law} -> law.enabled end),
      disabled_laws: Enum.count(laws, fn {_, law} -> not law.enabled end),
      laws_by_type: group_laws_by_type(laws),
      laws_by_enforcement_level: group_laws_by_enforcement_level(laws),
      total_history_entries: :ets.info(:law_history, :size)
    }
    
    {:reply, {:ok, statistics}, state}
  end

  @impl true
  def handle_call({:validate_law_definition, law_definition}, _from, state) do
    result = do_validate_law_definition(law_definition)
    {:reply, result, state}
  end

  # Helper functions
  defp initialize_default_laws() do
    default_laws = %{
      "information_conservation" => %{
        type: :information,
        description: "Information cannot be created or destroyed, only transformed",
        formula: "ΔI = 0",
        enforcement_level: :strict,
        enabled: true
      },
      "energy_conservation" => %{
        type: :energy,
        description: "Energy cannot be created or destroyed, only converted",
        formula: "ΔE = 0",
        enforcement_level: :strict,
        enabled: true
      },
      "momentum_conservation" => %{
        type: :momentum,
        description: "Momentum is conserved in isolated systems",
        formula: "Δp = 0",
        enforcement_level: :strict,
        enabled: true
      },
      "causal_closure" => %{
        type: :causal,
        description: "Causal relationships must be closed (∮C(t)dt ≥ 0)",
        formula: "∮C(t)dt ≥ 0",
        enforcement_level: :adaptive,
        enabled: true
      },
      "semantic_invertibility" => %{
        type: :semantic,
        description: "Semantic operations must be invertible (f⁻¹(f(Ω)) ≈ Ω)",
        formula: "f⁻¹(f(Ω)) ≈ Ω",
        enforcement_level: :adaptive,
        enabled: true
      },
      "computational_boundedness" => %{
        type: :computational,
        description: "Computational processes must be bounded (K(P) < B)",
        formula: "K(P) < B",
        enforcement_level: :adaptive,
        enabled: true
      }
    }

    Enum.each(default_laws, fn {law_id, law_data} ->
      law_record = create_law_data(law_id, law_data, [])
      :ets.insert(:conservation_laws, {law_id, law_record})
      
      record_law_history(law_id, :created, law_data)
    end)
  end

  defp create_law_data(law_id, law_definition, opts) do
    %{
      id: law_id,
      type: law_definition.type,
      description: law_definition.description,
      formula: law_definition.formula,
      enforcement_level: Keyword.get(opts, :enforcement_level, :adaptive),
      enabled: Keyword.get(opts, :enabled, true),
      created_at: System.system_time(:millisecond),
      updated_at: System.system_time(:millisecond),
      metadata: Keyword.get(opts, :metadata, %{})
    }
  end

  defp do_validate_law_definition(law_definition) when is_map(law_definition) do
    case law_definition do
      %{type: type, formula: formula} when is_binary(type) and is_binary(formula) ->
        case type do
          :information -> :ok
          :energy -> :ok
          :momentum -> :ok
          :causal -> :ok
          :semantic -> :ok
          :computational -> :ok
          _ -> {:error, :invalid_law_type}
        end
      _ ->
        {:error, :invalid_law_definition}
    end
  end

  defp do_validate_law_definition(_), do: {:error, :invalid_parameters}

  defp validate_modifications(law_data, modifications) when is_map(law_data) and is_map(modifications) do
    # Validate that modifications are allowed
    allowed_fields = [:enforcement_level, :description, :metadata]
    modified_fields = Map.keys(modifications)
    
    Enum.each(modified_fields, fn field ->
      if field not in allowed_fields do
        {:error, :unmodifiable_field}
      end
    end)
    
    :ok
  end

  defp validate_modifications(_, _), do: {:error, :invalid_parameters}

  defp apply_modifications(law_data, modifications) when is_map(law_data) and is_map(modifications) do
    updated_law = Map.merge(law_data, modifications)
    %{updated_law | updated_at: System.system_time(:millisecond)}
  end

  defp record_law_history(law_id, action, data) do
    history_record = %{
      timestamp: System.system_time(:millisecond),
      law_id: law_id,
      action: action,
      data: data
    }
    
    :ets.insert(:law_history, {history_record})
  end

  defp group_laws_by_type(laws) do
    laws
    |> Enum.group_by(fn {_, law} -> law.type end)
    |> Enum.map(fn {type, law_list} -> {type, length(law_list)} end)
    |> Map.new()
  end

  defp group_laws_by_enforcement_level(laws) do
    laws
    |> Enum.group_by(fn {_, law} -> law.enforcement_level end)
    |> Enum.map(fn {level, law_list} -> {level, length(law_list)} end)
    |> Map.new()
  end
end
