defmodule TiannaraRuntime.WorldModel.Counterfactual.AlternativeTimeline do
  @moduledoc """
  Represents an alternative timeline produced by a counterfactual branch, tracking the sequence of steps and the initial and final states.
  """

  @id_prefix "at_"

  @enforce_keys [:branch_id, :steps, :initial_state, :final_state, :total_steps]

  defstruct [
    :timeline_id,
    :branch_id,
    :steps,
    :initial_state,
    :final_state,
    :total_steps,
    :metadata
  ]

  @type t :: %__MODULE__{
          timeline_id: String.t() | nil,
          branch_id: String.t(),
          steps: list(),
          initial_state: any(),
          final_state: any(),
          total_steps: non_neg_integer(),
          metadata: map()
        }

  def new(opts) do
    struct = %__MODULE__{
      timeline_id: opts[:timeline_id],
      branch_id: opts[:branch_id],
      steps: opts[:steps],
      initial_state: opts[:initial_state],
      final_state: opts[:final_state],
      total_steps: opts[:total_steps],
      metadata: opts[:metadata] || %{}
    }

    case validate(struct) do
      :ok -> {:ok, ensure_id(struct)}
      {:error, _} = err -> err
    end
  end

  def validate(%__MODULE__{} = timeline) do
    errors = []

    errors =
      if is_nil(timeline.branch_id) or timeline.branch_id == "" do
        ["empty branch_id" | errors]
      else
        errors
      end

    errors =
      if is_nil(timeline.steps) do
        ["nil steps" | errors]
      else
        errors
      end

    errors =
      if not is_nil(timeline.steps) and timeline.steps == [] do
        ["empty steps" | errors]
      else
        errors
      end

    errors =
      if is_nil(timeline.initial_state) do
        ["nil initial_state" | errors]
      else
        errors
      end

    errors =
      if is_nil(timeline.final_state) do
        ["nil final_state" | errors]
      else
        errors
      end

    errors =
      if timeline.total_steps < 0 do
        ["total_steps < 0" | errors]
      else
        errors
      end

    errors =
      if is_list(timeline.steps) and timeline.total_steps != length(timeline.steps) do
        ["total_steps != length of steps" | errors]
      else
        errors
      end

    if errors == [], do: :ok, else: {:error, Enum.reverse(errors)}
  end

  def canonicalize(%__MODULE__{} = timeline) do
    timeline
    |> Map.from_struct()
    |> Enum.sort_by(fn {k, _v} -> k end)
    |> Map.new()
  end

  def compute_id(%__MODULE__{} = timeline) do
    material = (timeline.branch_id || "") <> inspect(timeline.initial_state || %{})
    hash = :crypto.hash(:sha256, material) |> Base.encode16(case: :lower)
    @id_prefix <> hash
  end

  defp ensure_id(%__MODULE__{timeline_id: nil} = timeline) do
    %{timeline | timeline_id: compute_id(timeline)}
  end

  defp ensure_id(%__MODULE__{} = timeline), do: timeline
end
