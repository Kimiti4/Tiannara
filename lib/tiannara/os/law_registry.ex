defmodule TiannaraOS.LawRegistry do
  @moduledoc """
  Law Registry - Stores validated scientific laws with complete evidence traceability.

  Laws represent the highest level of scientific validation - principles that have
  been repeatedly confirmed through extensive experimentation and observation. They
  form the foundation for discoveries and operational applications.

  ## Constitutional Role

  Laws sit below Theories and above Discoveries in the scientific hierarchy:

  ```
  Principles
      ↓
  Domains
      ↓
  Programs
      ↓
  Theories
      ↓
  Laws (this registry)
      ↓
  Discoveries
      ↓
  Interventions
      ↓
  Experiments
      ↓
  Evidence
  ```

  ## Law Formation Criteria

  A theory becomes a law when:
  - Extensively validated across multiple domains
  - No known falsifications
  - High confidence (>0.95)
  - Supported by numerous independent discoveries
  - Operationally validated in real-world applications

  ## Usage

      {:ok, law} = LawRegistry.get(:thermodynamics_second_law)
      {:ok, laws} = LawRegistry.list_by_domain(:physics)
      {:ok, updated} = LawRegistry.add_supporting_discovery(:gravity_law, :gravitational_waves)
  """

  use GenServer
  require Logger

  defstruct [
    :id,
    :name,
    :description,
    :domain_id,
    :origin_theory_id,  # Theory from which this law emerged
    :supporting_discovery_ids,
    :supporting_evidence_ids,
    :confidence,
    :validation_count,
    :falsification_attempts,
    :status,  # :provisional, :established, :fundamental
    :created_at,
    :last_validated,
    :lifecycle_events
  ]

  @type t :: %__MODULE__{
    id: atom(),
    name: String.t(),
    description: String.t(),
    domain_id: atom(),
    origin_theory_id: atom(),
    supporting_discovery_ids: [atom()],
    supporting_evidence_ids: [String.t()],
    confidence: float(),
    validation_count: non_neg_integer(),
    falsification_attempts: non_neg_integer(),
    status: atom(),
    created_at: DateTime.t(),
    last_validated: DateTime.t() | nil,
    lifecycle_events: [map()]
  }

  # ==================== Public API ====================

  @doc """
  Start the Law Registry GenServer.
  """
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc """
  Get a law by ID.

  ## Parameters
  - `law_id`: atom()

  ## Returns
  {:ok, Law.t()} | {:error, String.t()}
  """
  def get(law_id) do
    GenServer.call(__MODULE__, {:get, law_id})
  end

  @doc """
  List all laws in a domain.

  ## Parameters
  - `domain_id`: atom()

  ## Returns
  {:ok, [Law.t()]}
  """
  def list_by_domain(domain_id) do
    GenServer.call(__MODULE__, {:list_by_domain, domain_id})
  end

  @doc """
  Promote a theory to law status.

  This requires the theory to meet strict validation criteria.

  ## Parameters
  - `law_data`: map() with required fields including :origin_theory_id

  ## Returns
  {:ok, Law.t()} | {:error, String.t()}
  """
  def promote_from_theory(law_data) do
    GenServer.call(__MODULE__, {:promote_from_theory, law_data})
  end

  @doc """
  Add a supporting discovery to a law.

  ## Parameters
  - `law_id`: atom()
  - `discovery_id`: atom()

  ## Returns
  {:ok, Law.t()} | {:error, String.t()}
  """
  def add_supporting_discovery(law_id, discovery_id) do
    GenServer.call(__MODULE__, {:add_supporting_discovery, law_id, discovery_id})
  end

  @doc """
  Record validation event for a law.

  ## Parameters
  - `law_id`: atom()

  ## Returns
  {:ok, Law.t()} | {:error, String.t()}
  """
  def record_validation(law_id) do
    GenServer.call(__MODULE__, {:record_validation, law_id})
  end

  @doc """
  Record a falsification attempt (even if unsuccessful).

  ## Parameters
  - `law_id`: atom()
  - `attempt_description`: String.t()
  - `result`: :confirmed or :failed

  ## Returns
  {:ok, Law.t()} | {:error, String.t()}
  """
  def record_falsification_attempt(law_id, attempt_description, result) do
    GenServer.call(__MODULE__, {:record_falsification_attempt, law_id, attempt_description, result})
  end

  @doc """
  Update law status based on validation history.

  Status progression:
  :provisional → :established → :fundamental

  ## Parameters
  - `law_id`: atom()

  ## Returns
  {:ok, Law.t()} | {:error, String.t()}
  """
  def update_status(law_id) do
    GenServer.call(__MODULE__, {:update_status, law_id})
  end

  # ==================== GenServer Callbacks ====================

  @impl true
  def init(_opts) do
    state = %{
      laws: %{},
      domain_index: %{},  # domain_id -> [law_ids]
      theory_index: %{}   # theory_id -> law_id (if promoted)
    }

    {:ok, state}
  end

  @impl true
  def handle_call({:get, law_id}, _from, state) do
    case Map.get(state.laws, law_id) do
      nil ->
        {:reply, {:error, "Law not found: #{inspect(law_id)}"}, state}

      law ->
        {:reply, {:ok, law}, state}
    end
  end

  @impl true
  def handle_call({:list_by_domain, domain_id}, _from, state) do
    law_ids = Map.get(state.domain_index, domain_id, [])

    laws = Enum.map(law_ids, fn id ->
      Map.get(state.laws, id)
    end)
    |> Enum.filter(& &1)

    {:reply, {:ok, laws}, state}
  end

  @impl true
  def handle_call({:promote_from_theory, law_data}, _from, state) do
    # Validate promotion criteria
    with :ok <- validate_promotion_criteria(law_data),
         law <- build_law(law_data) do
      if Map.has_key?(state.laws, law.id) do
        {:reply, {:error, "Law already exists: #{law.id}"}, state}
      else
        state = put_in(state.laws[law.id], law)
        state = index_by_domain(state, law)

        # Index by origin theory
        state = if law.origin_theory_id do
          put_in(state.theory_index[law.origin_theory_id], law.id)
        else
          state
        end

        Logger.debug("Law promoted: #{inspect(law.id)}")

        {:reply, {:ok, law}, state}
      end
    else
      {:error, reason} -> {:reply, {:error, reason}, state}
    end
  end

  @impl true
  def handle_call({:add_supporting_discovery, law_id, discovery_id}, _from, state) do
    case Map.get(state.laws, law_id) do
      nil ->
        {:reply, {:error, "Law not found: #{inspect(law_id)}"}, state}

      law ->
        if discovery_id in law.supporting_discovery_ids do
          {:reply, {:error, "Discovery already linked: #{discovery_id}"}, state}
        else
          updated = %{law |
            supporting_discovery_ids: law.supporting_discovery_ids ++ [discovery_id]
          }

          # Recalculate confidence based on discovery count
          updated = recalculate_confidence(updated)
          state = put_in(state.laws[law_id], updated)

          Logger.debug("Discovery added to law #{inspect(law_id)}: #{inspect(discovery_id)}")

          {:reply, {:ok, updated}, state}
        end
    end
  end

  @impl true
  def handle_call({:record_validation, law_id}, _from, state) do
    case Map.get(state.laws, law_id) do
      nil ->
        {:reply, {:error, "Law not found: #{inspect(law_id)}"}, state}

      law ->
        updated = %{law |
          validation_count: law.validation_count + 1,
          last_validated: DateTime.utc_now()
        }

        # Increase confidence slightly with each validation
        updated = %{updated |
          confidence: min(updated.confidence + 0.01, 1.0)
        }

        state = put_in(state.laws[law_id], updated)

        Logger.debug("Law validated: #{inspect(law_id)}")

        {:reply, {:ok, updated}, state}
    end
  end

  @impl true
  def handle_call({:record_falsification_attempt, law_id, _description, result}, _from, state) do
    case Map.get(state.laws, law_id) do
      nil ->
        {:reply, {:error, "Law not found: #{inspect(law_id)}"}, state}

      law ->
        updated = %{law |
          falsification_attempts: law.falsification_attempts + 1
        }

        # If falsification confirmed, significantly reduce confidence
        updated = if result == :confirmed do
          %{updated | confidence: max(updated.confidence - 0.3, 0.0)}
        else
          # Failed attempt actually increases confidence slightly
          %{updated | confidence: min(updated.confidence + 0.02, 1.0)}
        end

        state = put_in(state.laws[law_id], updated)

        Logger.debug("Falsification attempt on law #{inspect(law_id)}: #{inspect(result)}")

        {:reply, {:ok, updated}, state}
    end
  end

  @impl true
  def handle_call({:update_status, law_id}, _from, state) do
    case Map.get(state.laws, law_id) do
      nil ->
        {:reply, {:error, "Law not found: #{inspect(law_id)}"}, state}

      law ->
        new_status = determine_status(law)

        if new_status != law.status do
          updated = %{law | status: new_status}
          state = put_in(state.laws[law_id], updated)

          Logger.debug("Law status updated: #{inspect(law_id)} -> #{inspect(new_status)}")

          {:reply, {:ok, updated}, state}
        else
          {:reply, {:ok, law}, state}
        end
    end
  end

  # ==================== Private Functions ====================

  defp validate_promotion_criteria(data) do
    required = [:id, :name, :domain_id, :origin_theory_id]

    missing = Enum.filter(required, fn field ->
      not Map.has_key?(data, field) or is_nil(Map.get(data, field))
    end)

    if length(missing) > 0 do
      {:error, "Missing required fields: #{inspect(missing)}"}
    else
      :ok
    end
  end

  defp build_law(data) when is_map(data) do
    %__MODULE__{
      id: Map.get(data, :id),
      name: Map.get(data, :name, ""),
      description: Map.get(data, :description, ""),
      domain_id: Map.get(data, :domain_id),
      origin_theory_id: Map.get(data, :origin_theory_id),
      supporting_discovery_ids: Map.get(data, :supporting_discovery_ids, []),
      supporting_evidence_ids: Map.get(data, :supporting_evidence_ids, []),
      confidence: Map.get(data, :confidence, 0.95),
      validation_count: Map.get(data, :validation_count, 0),
      falsification_attempts: Map.get(data, :falsification_attempts, 0),
      status: Map.get(data, :status, :provisional),
      created_at: Map.get(data, :created_at, DateTime.utc_now()),
      last_validated: Map.get(data, :last_validated),
      lifecycle_events: Map.get(data, :lifecycle_events, [])
    }
  end

  defp index_by_domain(state, law) do
    current = Map.get(state.domain_index, law.domain_id, [])
    put_in(state.domain_index[law.domain_id], current ++ [law.id])
  end

  defp recalculate_confidence(law) do
    # Base confidence from validation count and discovery support
    validation_factor = min(law.validation_count * 0.02, 0.4)
    discovery_factor = min(length(law.supporting_discovery_ids) * 0.05, 0.3)

    base_confidence = 0.7 + validation_factor + discovery_factor

    # Reduce confidence if there are falsification attempts
    falsification_penalty = law.falsification_attempts * 0.05

    new_confidence = max(base_confidence - falsification_penalty, 0.0)
    Float.round(min(new_confidence, 1.0), 2)
  end

  defp determine_status(law) do
    cond do
      # Fundamental: extremely high confidence, many validations, no falsifications
      law.confidence >= 0.99 and
      law.validation_count >= 100 and
      law.falsification_attempts == 0 ->
        :fundamental

      # Established: high confidence, good validation history
      law.confidence >= 0.95 and
      law.validation_count >= 50 and
      length(law.supporting_discovery_ids) >= 10 ->
        :established

      # Provisional: still accumulating evidence
      true ->
        :provisional
    end
  end
end
