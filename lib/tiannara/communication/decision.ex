defmodule Tiannara.Communication.Decision do
  @moduledoc """
  A communication decision: whether/how to notify a human about an epistemic
  event. Prevents notification spam while ensuring significant, actionable, and
  constitutional events reach human awareness.

  Constitutional basis: augmentation clause, Explainability, "Uncertainty
  should never be hidden."
  """
  defstruct [:event_type, :notify, :urgency, :significance, :human_relevance,
             :category, :reason, :suppress_reason, :evidence, :uncertainty,
             :recommended_action, :dedup_key, :already_notified]
end

defmodule Tiannara.Communication.DedupLedger do
  @moduledoc "Tracks already-notified events so humans are never spammed."
  defstruct seen: MapSet.new()

  def new, do: %__MODULE__{}
  def member?(%__MODULE__{seen: s}, key), do: MapSet.member?(s, key)
  def record(%__MODULE__{seen: s} = l, key), do: %{l | seen: MapSet.put(s, key)}
end