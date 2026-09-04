defmodule Tiannara.Metrics.HumanCollaborationTracker do
  @spec compute([map()]) :: map()
  def compute(sessions) when is_list(sessions) do
    closed = Enum.filter(sessions, &(&1.status == :closed))

    if closed == [] do
      %{
        total_reviews: 0,
        approval_rate: 0.0,
        rejection_rate: 0.0,
        modification_rate: 0.0,
        override_rate: 0.0,
        avg_review_time_ms: 0.0,
        collaboration_score: 0.0
      }
    else
      total = length(closed)

      approvals = Enum.count(closed, &(&1.decision == :approved))
      rejections = Enum.count(closed, &(&1.decision == :rejected))
      modifications = Enum.count(closed, &(&1.decision == :modified))

      overrides = Enum.count(closed, fn session ->
        Map.get(session.context, :system_recommendation) != session.decision
      end)

      review_times =
        Enum.map(closed, fn session ->
          case {session.opened_at, session.closed_at} do
            {opened, closed_at} when not is_nil(closed_at) ->
              DateTime.diff(closed_at, opened, :millisecond)
            _ -> 0
          end
        end)

      avg_time = Enum.sum(review_times) / total

      agreement_rate = approvals / total
      collaboration_score = compute_collaboration_score(agreement_rate, modifications / total)

      %{
        total_reviews: total,
        approval_rate: approvals / total,
        rejection_rate: rejections / total,
        modification_rate: modifications / total,
        override_rate: overrides / total,
        avg_review_time_ms: avg_time,
        collaboration_score: collaboration_score
      }
    end
  end

  defp compute_collaboration_score(agreement_rate, modification_rate) do
    agreement_score = 1.0 - abs(agreement_rate - 0.7) * 2.0
    modification_score = min(1.0, modification_rate * 3.0)
    max(0.0, (agreement_score * 0.6 + modification_score * 0.4))
  end
end
