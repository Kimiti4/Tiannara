defmodule TiannaraRuntime.Mathematics.MathematicsRegistry do
  @moduledoc """
  Phase 16.X.2 — Mathematics Registry

  Manages identifiers, registrations, and lifecycle definitions for all
  mathematical objects in Phase 16.X.

  Lifecycle states: proposed → active → deprecated → archived
                    active → frozen (terminal, constitutional seal)
  """

  @registry_table :math_registry
  @valid_types ~w(Axiom Definition Structure Conjecture Lemma Theorem Proof
                  Corollary Counterexample Algorithm Application
                  MathematicalProgram MathematicalExperiment MathematicalAssertion
                  ArchaeologyRecord SymbolicExpression SymbolicRule RuleSet
                  DomainRegistration RewriteStep RewriteLog ProofStep
                  InferenceRule AxiomSet ProofBundle SystemModel
                  BoundedVerificationConfig)
  @valid_lifecycles ~w(proposed active deprecated archived frozen)

  # ---------------------------------------------------------------------------
  # ETS Initialization
  # ---------------------------------------------------------------------------

  @doc "Create or retrieve the registry ETS table."
  @spec init_table() :: :ok
  def init_table do
    if :ets.info(@registry_table) == :undefined do
      :ets.new(@registry_table, [:set, :public, :named_table])
    end
    :ok
  end

  @doc "Destroy and recreate the registry table (test isolation)."
  @spec reset_table() :: :ok
  def reset_table do
    if :ets.info(@registry_table) != :undefined, do: :ets.delete(@registry_table)
    init_table()
  end

  # ---------------------------------------------------------------------------
  # Registration
  # ---------------------------------------------------------------------------

  @doc "Register a mathematical artifact. Returns {:ok, registration_id}."
  @spec register(String.t(), String.t(), map()) :: {:ok, String.t()} | {:error, String.t()}
  def register(artifact_type, artifact_id, metadata \\ %{}) do
    init_table()
    with :ok <- validate_type(artifact_type),
         :ok <- validate_id(artifact_id) do
      registration_id = compute_registration_id(artifact_type, artifact_id)

      case :ets.lookup(@registry_table, registration_id) do
        [{^registration_id, _}] ->
          {:error, "already registered: #{registration_id}"}
        [] ->
          entry = %{
            "registration_id" => registration_id,
            "artifact_type" => artifact_type,
            "artifact_id" => artifact_id,
            "owner" => "Constitutional Research Council",
            "lifecycle" => "proposed",
            "metadata" => metadata
          }
          :ets.insert(@registry_table, {registration_id, entry})
          {:ok, registration_id}
      end
    end
  end

  @doc "Look up a registration by its registration_id."
  @spec lookup(String.t()) :: {:ok, map()} | {:error, String.t()}
  def lookup(registration_id) when is_binary(registration_id) do
    case :ets.lookup(@registry_table, registration_id) do
      [{^registration_id, entry}] -> {:ok, entry}
      [] -> {:error, "registration not found: #{registration_id}"}
    end
  end

  @doc "Find all registrations for a given artifact type."
  @spec find_by_type(String.t()) :: {:ok, [map()]}
  def find_by_type(artifact_type) when is_binary(artifact_type) do
    results =
      @registry_table
      |> :ets.tab2list()
      |> Enum.map(fn {_id, entry} -> entry end)
      |> Enum.filter(fn entry -> Map.get(entry, "artifact_type") == artifact_type end)
      |> Enum.sort_by(fn entry -> Map.get(entry, "registration_id") end)
    {:ok, results}
  end

  @doc "Get the lifecycle state of a registration."
  @spec lifecycle(String.t()) :: {:ok, String.t()} | {:error, String.t()}
  def lifecycle(registration_id) do
    case lookup(registration_id) do
      {:ok, entry} -> {:ok, Map.get(entry, "lifecycle")}
      error -> error
    end
  end

  @doc "Transition lifecycle state. Returns {:ok, entry} on success."
  @spec transition(String.t(), String.t()) :: {:ok, map()} | {:error, String.t()}
  def transition(registration_id, new_state) do
    with {:ok, entry} <- lookup(registration_id),
         current = Map.get(entry, "lifecycle"),
         :ok <- validate_lifecycle(new_state),
         :ok <- valid_transition?(current, new_state) do
      updated = Map.put(entry, "lifecycle", new_state)
      :ets.insert(@registry_table, {registration_id, updated})
      {:ok, updated}
    end
  end

  @doc "List all active (not archived/frozen) registrations."
  @spec list_active() :: {:ok, [map()]}
  def list_active do
    results =
      @registry_table
      |> :ets.tab2list()
      |> Enum.map(fn {_id, entry} -> entry end)
      |> Enum.reject(fn entry ->
        Map.get(entry, "lifecycle") in ~w(archived frozen)
      end)
      |> Enum.sort_by(fn entry -> Map.get(entry, "registration_id") end)
    {:ok, results}
  end

  @doc "Check if an artifact_id is registered."
  @spec registered?(String.t()) :: boolean()
  def registered?(artifact_id) when is_binary(artifact_id) do
    @registry_table
    |> :ets.tab2list()
    |> Enum.any?(fn {_id, entry} -> Map.get(entry, "artifact_id") == artifact_id end)
  end

  # ---------------------------------------------------------------------------
  # Valid Types / Lifecycles
  # ---------------------------------------------------------------------------

  @doc "Returns all valid artifact types."
  @spec valid_types() :: [String.t()]
  def valid_types, do: @valid_types

  @doc "Returns all valid lifecycle states."
  @spec valid_lifecycles() :: [String.t()]
  def valid_lifecycles, do: @valid_lifecycles

  # ---------------------------------------------------------------------------
  # Internal
  # ---------------------------------------------------------------------------

  defp compute_registration_id(artifact_type, artifact_id) do
    "reg_" <>
      TiannaraRuntime.Mathematics.MathematicalID.from_canonical_map(%{
        "type" => artifact_type,
        "id" => artifact_id
      })
  end

  defp validate_type(type) when type in @valid_types, do: :ok
  defp validate_type(type), do: {:error, "invalid artifact type: #{type}"}

  defp validate_id(id) when is_binary(id) and byte_size(id) > 0, do: :ok
  defp validate_id(_), do: {:error, "artifact_id must be a non-empty string"}

  defp validate_lifecycle(state) when state in @valid_lifecycles, do: :ok
  defp validate_lifecycle(state), do: {:error, "invalid lifecycle state: #{state}"}

  defp valid_transition?("proposed", "active"), do: :ok
  defp valid_transition?("active", "deprecated"), do: :ok
  defp valid_transition?("active", "archived"), do: :ok
  defp valid_transition?("active", "frozen"), do: :ok
  defp valid_transition?("deprecated", "archived"), do: :ok
  defp valid_transition?(current, _new),
    do: {:error, "invalid transition from #{current}"}
end
