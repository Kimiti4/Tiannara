defmodule TiannaraOS.TheoryRegistry do
  @moduledoc """
  Theory Registry - Stores and manages scientific theories with competition tracking.

  Theories track hypotheses, predictions, evidence, falsifications, and confidence
  levels. Multiple competing theories can coexist for the same phenomena, each with
  their own validation history.

  ## Constitutional Role

  Theories sit below Research Programs in the scientific hierarchy:

  ```
  Principles
      ↓
  Domains
      ↓
  Research Programs
      ↓
  Theories (this registry)
      ↓
  Laws
      ↓
  Discoveries
  ```

  ## Theory Competition

  Competing theories coexist and track:
  - predictions made
  - successful predictions
  - failed predictions
  - supporting evidence
  - falsifications
  - confidence level

  No theory becomes canonical permanently. Confidence evolves based on evidence.

  ## Usage

      {:ok, theory} = TheoryRegistry.get(:relativity_theory)
      {:ok, competitors} = TheoryRegistry.get_competitors(:gravity_explanation)
      {:ok, updated} = TheoryRegistry.record_prediction_success(:quantum_mechanics, prediction_id)
  """

  use GenServer
  require Logger

  defstruct [
    :id,
    :name,
    :description,
    :domain_id,
    :program_id,
    :hypothesis,
    :predictions,
    :successful_predictions,
    :failed_predictions,
    :supporting_evidence_ids,
    :falsifications,
    :confidence,
    :status,  # :active, :falsified, :superseded, :canonical
    :created_at,
    :last_updated,
    :competitor_group_id,  # Groups competing theories
    :lifecycle_events
  ]

  @type t :: %__MODULE__{
    id: atom(),
    name: String.t(),
    description: String.t(),
    domain_id: atom(),
    program_id: atom(),
    hypothesis: String.t(),
    predictions: [map()],
    successful_predictions: [String.t()],
    failed_predictions: [String.t()],
    supporting_evidence_ids: [String.t()],
    falsifications: [map()],
    confidence: float(),
    status: atom(),
    created_at: DateTime.t(),
    last_updated: DateTime.t(),
    competitor_group_id: atom() | nil,
    lifecycle_events: [map()]
  }

  # ==================== Public API ====================

  @doc """
  Start the Theory Registry GenServer.
  """
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc """
  Get a theory by ID.

  ## Parameters
  - `theory_id`: atom()

  ## Returns
  {:ok, Theory.t()} | {:error, String.t()}
  """
  def get(theory_id) do
    GenServer.call(__MODULE__, {:get, theory_id})
  end

  @doc """
  List all theories in a domain.

  ## Parameters
  - `domain_id`: atom()

  ## Returns
  {:ok, [Theory.t()]}
  """
  def list_by_domain(domain_id) do
    GenServer.call(__MODULE__, {:list_by_domain, domain_id})
  end

  @doc """
  Get competing theories for a given phenomenon.

  ## Parameters
  - `competitor_group_id`: atom()

  ## Returns
  {:ok, [Theory.t()]}
  """
  def get_competitors(competitor_group_id) do
    GenServer.call(__MODULE__, {:get_competitors, competitor_group_id})
  end

  @doc """
  Register a new theory.

  ## Parameters
  - `theory_data`: map() with required fields

  ## Returns
  {:ok, Theory.t()} | {:error, String.t()}
  """
  def register(theory_data) do
    GenServer.call(__MODULE__, {:register, theory_data})
  end

  @doc """
  Record a successful prediction for a theory.

  ## Parameters
  - `theory_id`: atom()
  - `prediction_id`: String.t()

  ## Returns
  {:ok, Theory.t()} | {:error, String.t()}
  """
  def record_prediction_success(theory_id, prediction_id) do
    GenServer.call(__MODULE__, {:record_prediction_success, theory_id, prediction_id})
  end

  @doc """
  Record a failed prediction (falsification) for a theory.

  ## Parameters
  - `theory_id`: atom()
  - `prediction_id`: String.t()
  - `reason`: String.t()

  ## Returns
  {:ok, Theory.t()} | {:error, String.t()}
  """
  def record_prediction_failure(theory_id, prediction_id, reason) do
    GenServer.call(__MODULE__, {:record_prediction_failure, theory_id, prediction_id, reason})
  end

  @doc """
  Add supporting evidence to a theory.

  ## Parameters
  - `theory_id`: atom()
  - `evidence_id`: String.t()

  ## Returns
  {:ok, Theory.t()} | {:error, String.t()}
  """
  def add_supporting_evidence(theory_id, evidence_id) do
    GenServer.call(__MODULE__, {:add_supporting_evidence, theory_id, evidence_id})
  end

  @doc """
  Update theory confidence based on new evidence.

  ## Parameters
  - `theory_id`: atom()
  - `new_confidence`: float() (0.0 to 1.0)

  ## Returns
  {:ok, Theory.t()} | {:error, String.t()}
  """
  def update_confidence(theory_id, new_confidence) do
    GenServer.call(__MODULE__, {:update_confidence, theory_id, new_confidence})
  end

  # ==================== GenServer Callbacks ====================

  @impl true
  def init(_opts) do
    state = %{
      theories: %{},
      domain_index: %{},  # domain_id -> [theory_ids]
      competitor_groups: %{}  # group_id -> [theory_ids]
    }

    {:ok, state}
  end

  @impl true
  def handle_call({:get, theory_id}, _from, state) do
    case Map.get(state.theories, theory_id) do
      nil ->
        {:reply, {:error, "Theory not found: #{inspect(theory_id)}"}, state}

      theory ->
        {:reply, {:ok, theory}, state}
    end
  end

  @impl true
  def handle_call({:list_by_domain, domain_id}, _from, state) do
    theory_ids = Map.get(state.domain_index, domain_id, [])

    theories = Enum.map(theory_ids, fn id ->
      Map.get(state.theories, id)
    end)
    |> Enum.filter(& &1)

    {:reply, {:ok, theories}, state}
  end

  @impl true
  def handle_call({:get_competitors, competitor_group_id}, _from, state) do
    theory_ids = Map.get(state.competitor_groups, competitor_group_id, [])

    theories = Enum.map(theory_ids, fn id ->
      Map.get(state.theories, id)
    end)
    |> Enum.filter(& &1)

    {:reply, {:ok, theories}, state}
  end

  @impl true
  def handle_call({:register, theory_data}, _from, state) do
    theory = build_theory(theory_data)

    if Map.has_key?(state.theories, theory.id) do
      {:reply, {:error, "Theory already exists: #{theory.id}"}, state}
    else
      state = put_in(state.theories[theory.id], theory)
      state = index_by_domain(state, theory)
      state = index_by_competitor_group(state, theory)

      Logger.debug("[TheoryRegistry] track_entity(:theory, #{theory.id}, :registered) — module not yet available")

      {:reply, {:ok, theory}, state}
    end
  end

  @impl true
  def handle_call({:record_prediction_success, theory_id, prediction_id}, _from, state) do
    case Map.get(state.theories, theory_id) do
      nil ->
        {:reply, {:error, "Theory not found: #{inspect(theory_id)}"}, state}

      theory ->
        if prediction_id in theory.successful_predictions do
          {:reply, {:error, "Prediction already recorded as success: #{prediction_id}"}, state}
        else
          updated = %{theory |
            successful_predictions: theory.successful_predictions ++ [prediction_id],
            last_updated: DateTime.utc_now()
          }

          # Recalculate confidence
          updated = recalculate_confidence(updated)
          state = put_in(state.theories[theory_id], updated)

          Logger.debug("[TheoryRegistry] track_entity(:theory, #{theory_id}, :prediction_success) — module not yet available")

          {:reply, {:ok, updated}, state}
        end
    end
  end

  @impl true
  def handle_call({:record_prediction_failure, theory_id, prediction_id, reason}, _from, state) do
    case Map.get(state.theories, theory_id) do
      nil ->
        {:reply, {:error, "Theory not found: #{inspect(theory_id)}"}, state}

      theory ->
        falsification = %{
          prediction_id: prediction_id,
          reason: reason,
          timestamp: DateTime.utc_now()
        }

        updated = %{theory |
          failed_predictions: theory.failed_predictions ++ [prediction_id],
          falsifications: theory.falsifications ++ [falsification],
          last_updated: DateTime.utc_now()
        }

        # Recalculate confidence (decrease due to falsification)
        updated = recalculate_confidence(updated)

        # Mark as falsified if confidence drops too low
        updated = if updated.confidence < 0.2 do
          %{updated | status: :falsified}
        else
          updated
        end

        state = put_in(state.theories[theory_id], updated)

        Logger.debug("[TheoryRegistry] track_entity(:theory, #{theory_id}, :prediction_failure) — module not yet available")

        {:reply, {:ok, updated}, state}
    end
  end

  @impl true
  def handle_call({:add_supporting_evidence, theory_id, evidence_id}, _from, state) do
    case Map.get(state.theories, theory_id) do
      nil ->
        {:reply, {:error, "Theory not found: #{inspect(theory_id)}"}, state}

      theory ->
        if evidence_id in theory.supporting_evidence_ids do
          {:reply, {:error, "Evidence already linked: #{evidence_id}"}, state}
        else
          updated = %{theory |
            supporting_evidence_ids: theory.supporting_evidence_ids ++ [evidence_id],
            last_updated: DateTime.utc_now()
          }

          updated = recalculate_confidence(updated)
          state = put_in(state.theories[theory_id], updated)

          Logger.debug("[TheoryRegistry] track_entity(:theory, #{theory_id}, :evidence_added) — module not yet available")

          {:reply, {:ok, updated}, state}
        end
    end
  end

  @impl true
  def handle_call({:update_confidence, theory_id, new_confidence}, _from, state) do
    case Map.get(state.theories, theory_id) do
      nil ->
        {:reply, {:error, "Theory not found: #{inspect(theory_id)}"}, state}

      theory ->
        if new_confidence < 0.0 or new_confidence > 1.0 do
          {:reply, {:error, "Confidence must be between 0.0 and 1.0"}, state}
        else
          updated = %{theory |
            confidence: new_confidence,
            last_updated: DateTime.utc_now()
          }

          state = put_in(state.theories[theory_id], updated)

          Logger.debug("[TheoryRegistry] track_entity(:theory, #{theory_id}, :confidence_updated) — module not yet available")

          {:reply, {:ok, updated}, state}
        end
    end
  end

  # ==================== Private Functions ====================

  defp build_theory(data) when is_map(data) do
    %__MODULE__{
      id: Map.get(data, :id),
      name: Map.get(data, :name, ""),
      description: Map.get(data, :description, ""),
      domain_id: Map.get(data, :domain_id),
      program_id: Map.get(data, :program_id),
      hypothesis: Map.get(data, :hypothesis, ""),
      predictions: Map.get(data, :predictions, []),
      successful_predictions: Map.get(data, :successful_predictions, []),
      failed_predictions: Map.get(data, :failed_predictions, []),
      supporting_evidence_ids: Map.get(data, :supporting_evidence_ids, []),
      falsifications: Map.get(data, :falsifications, []),
      confidence: Map.get(data, :confidence, 0.5),
      status: Map.get(data, :status, :active),
      created_at: Map.get(data, :created_at, DateTime.utc_now()),
      last_updated: Map.get(data, :last_updated, DateTime.utc_now()),
      competitor_group_id: Map.get(data, :competitor_group_id),
      lifecycle_events: Map.get(data, :lifecycle_events, [])
    }
  end

  defp index_by_domain(state, theory) do
    current = Map.get(state.domain_index, theory.domain_id, [])
    put_in(state.domain_index[theory.domain_id], current ++ [theory.id])
  end

  defp index_by_competitor_group(state, theory) do
    if theory.competitor_group_id do
      current = Map.get(state.competitor_groups, theory.competitor_group_id, [])
      put_in(state.competitor_groups[theory.competitor_group_id], current ++ [theory.id])
    else
      state
    end
  end

  defp recalculate_confidence(theory) do
    total_predictions = length(theory.successful_predictions) + length(theory.failed_predictions)

    if total_predictions == 0 do
      # Base confidence from evidence count
      evidence_factor = min(length(theory.supporting_evidence_ids) * 0.1, 0.8)
      Float.round(evidence_factor, 2)
    else
      # Calculate from prediction success rate
      success_rate = length(theory.successful_predictions) / total_predictions

      # Weight by evidence count
      evidence_weight = min(length(theory.supporting_evidence_ids) * 0.05, 0.3)

      confidence = (success_rate * 0.7) + evidence_weight
      Float.round(min(confidence, 1.0), 2)
    end
  end

  def list_all, do: {:ok, []}
end
