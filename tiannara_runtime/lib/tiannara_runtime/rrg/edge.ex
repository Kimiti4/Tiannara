defmodule Tiannara.RRG.Edge do
  @moduledoc """
  Epistemic Relation Edge - Represents connections between ontology nodes.
  Defines the relationship type, strength, and latency between nodes.
  """

  defstruct [
    :from,
    :to,
    :type,
    :strength,
    :latency_weight,
    :created_at,
    :last_updated
  ]

  @type edge_type :: :supports | :contradicts | :derives | :observed_by

  def new(from_id, to_id, type, opts \\ []) when type in [:supports, :contradicts, :derives, :observed_by] do
    %__MODULE__{
      from: from_id,
      to: to_id,
      type: type,
      strength: Keyword.get(opts, :strength, 1.0),
      latency_weight: Keyword.get(opts, :latency_weight, 0.0),
      created_at: Keyword.get(opts, :created_at, System.system_time(:millisecond)),
      last_updated: Keyword.get(opts, :last_updated, System.system_time(:millisecond))
    }
  end

  def update_strength(edge, new_strength) when is_number(new_strength) do
    %{edge | strength: new_strength, last_updated: System.system_time(:millisecond)}
  end

  def update_latency(edge, new_latency) when is_number(new_latency) do
    %{edge | latency_weight: new_latency, last_updated: System.system_time(:millisecond)}
  end

  def is_supporting?(edge) do
    edge.type == :supports
  end

  def is_contradicting?(edge) do
    edge.type == :contradicts
  end

  def is_deriving?(edge) do
    edge.type == :derives
  end

  def is_observation?(edge) do
    edge.type == :observed_by
  end

  def valid_type?(type) do
    type in [:supports, :contradicts, :derives, :observed_by]
  end

  def get_relationship_direction(edge) do
    case edge.type do
      :supports -> :positive
      :contradicts -> :negative
      :derives -> :causal_forward
      :observed_by -> :observational
    end
  end
end
