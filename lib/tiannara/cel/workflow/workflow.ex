defmodule Tiannara.CEL.Workflow.Workflow do
  @moduledoc """
  Declarative workflow definition for the scientific method.

  A workflow is a sequence of steps, each with:
    - A capability requirement (resolved via CapabilityGraph)
    - Input/output schemas
    - Timeout and retry policy
    - Compensation action (for saga rollback)
    - Constitutional metadata (evidence, confidence, human oversight)

  Workflows are immutable once started. State mutations produce new versions,
  preserving lineage per the Evolution Framework.

  Constitutional Alignment (rules.md):
    - "Scientific Method": Steps map to the canonical scientific process.
    - "Every architectural decision should remain traceable": Workflow lineage is preserved.
    - "Recover gracefully": Saga compensation ensures stable-state preservation.
  """

  defstruct [
    :id,
    :mission_id,
    :name,
    :description,
    :steps,
    :started_at,
    :completed_at,
    :error,
    status: :pending,
    current_step_index: 0,
    step_results: [],
    checkpoint: %{},
    compensation_log: [],
    outcome_evidence: [],
    impact_level: :standard,
    context: %{},
    metadata: %{},
    version: "1.0.0"
  ]

  @type impact_level :: :standard | :high | :critical
  @type workflow_status ::
          :pending | :running | :paused | :completed | :failed | :compensating | :cancelled

  @type t :: %__MODULE__{
          id: String.t(),
          mission_id: String.t() | nil,
          name: String.t(),
          description: String.t() | nil,
          steps: [Tiannara.CEL.Workflow.Step.t()],
          status: workflow_status(),
          current_step_index: non_neg_integer(),
          step_results: [Tiannara.CEL.Workflow.StepResult.t()],
          checkpoint: map(),
          compensation_log: [map()],
          outcome_evidence: [map()],
          impact_level: impact_level(),
          started_at: DateTime.t() | nil,
          completed_at: DateTime.t() | nil,
          error: term() | nil,
          context: map(),
          metadata: map(),
          version: String.t()
        }

  @behaviour Access

  def fetch(%__MODULE__{} = workflow, key),
    do: Map.fetch(workflow, key)

  def get_and_update(%__MODULE__{} = workflow, key, fun)
      when is_atom(key) do
    current = Map.get(workflow, key)
    {current, updated} = fun.(current)
    {current, Map.put(workflow, key, updated)}
  end

  def pop(%__MODULE__{} = workflow, key) when is_atom(key) do
    {Map.get(workflow, key), Map.delete(workflow, key)}
  end

  def new(name, steps, opts \\ []) do
    %__MODULE__{
      id: Keyword.get(opts, :id) || generate_id(),
      mission_id: Keyword.get(opts, :mission_id),
      name: name,
      description: Keyword.get(opts, :description),
      steps: List.wrap(steps),
      impact_level: Keyword.get(opts, :impact_level, :standard),
      context: Keyword.get(opts, :context, %{}),
      metadata: Keyword.get(opts, :metadata, %{})
    }
  end

  def validate(%__MODULE__{steps: []}), do: {:error, :no_steps}
  def validate(%__MODULE__{steps: steps} = workflow) do
    with :ok <- validate_step_sequence(steps) do
      {:ok, workflow}
    end
  end

  def add_step(workflow, step) do
    %{workflow | steps: workflow.steps ++ [step]}
  end

  def current_step(workflow) do
    Enum.at(workflow.steps, workflow.current_step_index)
  end

  def completed?(workflow) do
    workflow.status in [:completed, :failed, :cancelled]
  end

  def duration_ms(workflow) do
    with %DateTime{} = started <- workflow.started_at,
         %DateTime{} = completed <- workflow.completed_at do
      DateTime.diff(completed, started, :millisecond)
    else
      _ -> 0
    end
  end

  defp validate_step_sequence(steps) do
    ids = Enum.map(steps, & &1.id)
    if length(ids) == length(Enum.uniq(ids)), do: :ok, else: {:error, :duplicate_step_ids}
  end

  defp generate_id do
    "wf_#{:crypto.strong_rand_bytes(8) |> Base.encode16(case: :lower)}"
  end
end
