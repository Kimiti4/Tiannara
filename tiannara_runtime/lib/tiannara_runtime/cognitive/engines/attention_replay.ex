defmodule TiannaraRuntime.Cognitive.Engines.AttentionReplay do
  @moduledoc false

  alias TiannaraRuntime.Cognitive.Engines.{PriorityEvaluator, AttentionPolicy}

  def record(attention_state) do
    fingerprint = stable_fingerprint(attention_state)
    {:ok, %{
      fingerprint: fingerprint,
      timestamp: :erlang.system_time(:millisecond),
      state: attention_state
    }}
  end

  defp stable_fingerprint(state) do
    canonical =
      state
      |> Enum.sort_by(fn {k, _} -> k end)
      |> Enum.map(fn {k, v} -> "#{k}:#{inspect(v)}" end)
      |> Enum.join("|")
    :crypto.hash(:sha256, canonical) |> Base.encode16(case: :lower)
  end

  def verify_ordering(tasks, criteria \\ AttentionPolicy.get_default_criteria()) do
    ordered = PriorityEvaluator.sort_by_score(tasks, criteria)
    {:ok, %{ordered: ordered, count: length(ordered)}}
  end
end
