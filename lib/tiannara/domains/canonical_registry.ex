defmodule Tiannara.Domains.CanonicalRegistry do
  @moduledoc """
  AC-001-A: Canonical domain identity registry.

  Establishes the authoritative 20-domain ontology. This registry owns:
  - Domain identity
  - Domain metadata
  - Domain → module binding
  - Domain lifecycle state
  - Ontology version

  This registry does NOT own:
  - Knowledge capital (separate service)
  - Portfolio vectors (separate service)
  - Research metrics (separate service)

  Excluded from canonical ontology:
  - :science (methodology, not domain)
  - :mathematics (epistemic substrate)
  - :logic (epistemic substrate)
  - :cs (merged into :computation)

  Constitutional basis:
    - "Prefer many specialized components cooperating through well-defined interfaces"
    - "Each subsystem should have clear responsibilities, explicit interfaces, minimal coupling"
  """

  use GenServer

  @ontology_version "1.0.0"

  @canonical_domains [
    :engineering,
    :physics,
    :chemistry,
    :medicine,
    :cybernetics,
    :governance,
    :computation,
    :agriculture,
    :energy,
    :logistics,
    :cognition,
    :materials,
    :robotics,
    :economics,
    :philosophy,
    :sociology,
    :linguistics,
    :aerospace,
    :ecology,
    :architecture
  ]

  @type domain_id :: atom()
  @type lifecycle :: :active | :deprecated | :experimental

  @type domain_record :: %{
          id: domain_id(),
          module: module() | nil,
          metadata: map(),
          lifecycle: lifecycle(),
          name: binary(),
          description: binary(),
          active_programs: [atom()],
          last_research_activity: DateTime.t() | nil
        }

  # --- Client API ---

  @doc """
  Start the canonical registry GenServer.
  """
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc """
  Return all 20 canonical domain IDs.
  """
  @spec all() :: [domain_id()]
  def all do
    GenServer.call(__MODULE__, :all)
  end

  @doc """
  Return all 20 canonical domain records in a single atomic GenServer call.

  C0 established that 9 consumers require complete domain records.
  This is implemented atomically to avoid N+1 GenServer-call patterns.

  Returns records in canonical order.
  """
  @spec all_records() :: [domain_record()]
  def all_records do
    GenServer.call(__MODULE__, :all_records)
  end

  @doc """
  Get complete domain record by ID.
  """
  @spec get(domain_id()) :: {:ok, domain_record()} | {:error, :not_found}
  def get(domain_id) do
    GenServer.call(__MODULE__, {:get, domain_id})
  end

  @doc """
  Get domain metadata by ID.
  """
  @spec get_metadata(domain_id()) :: {:ok, map()} | {:error, :not_found}
  def get_metadata(domain_id) do
    GenServer.call(__MODULE__, {:get_metadata, domain_id})
  end

  @doc """
  Get domain module binding by ID.
  """
  @spec get_module(domain_id()) :: {:ok, module() | nil} | {:error, :not_found}
  def get_module(domain_id) do
    GenServer.call(__MODULE__, {:get_module, domain_id})
  end

  @doc """
  Get domain lifecycle state by ID.
  """
  @spec get_lifecycle(domain_id()) :: {:ok, lifecycle()} | {:error, :not_found}
  def get_lifecycle(domain_id) do
    GenServer.call(__MODULE__, {:get_lifecycle, domain_id})
  end

  @doc """
  Return the canonical ontology version.
  """
  @spec ontology_version() :: binary()
  def ontology_version do
    @ontology_version
  end

  # --- Server Callbacks ---

  @impl true
  def init(_opts) do
    state = %{
      domains: initialize_canonical_domains(),
      canonical_ids: MapSet.new(@canonical_domains)
    }

    {:ok, state}
  end

  @impl true
  def handle_call(:all, _from, state) do
    {:reply, @canonical_domains, state}
  end

  @impl true
  def handle_call(:all_records, _from, state) do
    records =
      @canonical_domains
      |> Enum.map(fn id -> Map.fetch!(state.domains, id) end)

    {:reply, records, state}
  end

  @impl true
  def handle_call({:get, domain_id}, _from, state) do
    case Map.get(state.domains, domain_id) do
      nil -> {:reply, {:error, :not_found}, state}
      record -> {:reply, {:ok, record}, state}
    end
  end

  @impl true
  def handle_call({:get_metadata, domain_id}, _from, state) do
    case Map.get(state.domains, domain_id) do
      nil -> {:reply, {:error, :not_found}, state}
      record -> {:reply, {:ok, record.metadata}, state}
    end
  end

  @impl true
  def handle_call({:get_module, domain_id}, _from, state) do
    case Map.get(state.domains, domain_id) do
      nil -> {:reply, {:error, :not_found}, state}
      record -> {:reply, {:ok, record.module}, state}
    end
  end

  @impl true
  def handle_call({:get_lifecycle, domain_id}, _from, state) do
    case Map.get(state.domains, domain_id) do
      nil -> {:reply, {:error, :not_found}, state}
      record -> {:reply, {:ok, record.lifecycle}, state}
    end
  end

  # --- Helpers ---

  defp initialize_canonical_domains do
    @canonical_domains
    |> Enum.map(fn id ->
      meta = default_metadata(id)

      {id,
       %{
         id: id,
         module: domain_module(id),
         metadata: meta,
         lifecycle: :active,
         name: meta.name,
         description: meta.description,
         active_programs: [],
         last_research_activity: nil
       }}
    end)
    |> Map.new()
  end

  defp domain_module(:engineering), do: Tiannara.Domains.Engineering
  defp domain_module(:physics), do: Tiannara.Domains.Physics
  defp domain_module(:chemistry), do: Tiannara.Domains.Chemistry
  defp domain_module(:medicine), do: Tiannara.Domains.Medicine
  defp domain_module(:cybernetics), do: Tiannara.Domains.Cybernetics
  defp domain_module(:governance), do: Tiannara.Domains.Governance
  defp domain_module(:computation), do: Tiannara.Domains.Computation
  defp domain_module(:agriculture), do: Tiannara.Domains.Agriculture
  defp domain_module(:energy), do: Tiannara.Domains.Energy
  defp domain_module(:logistics), do: Tiannara.Domains.Logistics
  defp domain_module(:cognition), do: Tiannara.Domains.Cognition
  defp domain_module(:materials), do: Tiannara.Domains.Materials
  defp domain_module(:robotics), do: Tiannara.Domains.Robotics
  defp domain_module(:economics), do: Tiannara.Domains.Economics
  defp domain_module(:philosophy), do: Tiannara.Domains.Philosophy
  defp domain_module(:sociology), do: Tiannara.Domains.Sociology
  defp domain_module(:linguistics), do: Tiannara.Domains.Linguistics
  defp domain_module(:aerospace), do: Tiannara.Domains.Aerospace
  defp domain_module(:ecology), do: Tiannara.Domains.Ecology
  defp domain_module(:architecture), do: Tiannara.Domains.Architecture

  defp default_metadata(id) do
    %{
      name: Atom.to_string(id) |> String.capitalize(),
      description: "Canonical #{id} domain",
      version: "0.1.0"
    }
  end
end
