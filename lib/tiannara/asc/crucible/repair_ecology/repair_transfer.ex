defmodule Tiannara.ASC.Crucible.RepairEcology.RepairTransfer do
  @moduledoc """
  Repair Transfer — tracks cross-project transfer of repair patterns.

  This is the most critical module for discovering engineering laws, as highly
  transferable repairs suggest universal principles rather than project-specific fixes.

  Responsibilities:
  - Track when a pattern discovered in one project is applied to another
  - Calculate transferability scores
  - Record transfer success/failure events
  - Identify cross-domain transfer patterns

  ## Success Criteria

  - transfer_events ≥ 100
  - transferability_score > 40%
  - cross_project_transfers tracked
  - cross_domain_transfers tracked

  ## Example

      iex> transfer = RepairTransfer.execute(pattern, source_project, target_project, success?, fitness_delta)
      iex> transfer.success
      true

  """

  alias Tiannara.ASC.Crucible.RepairPattern

  @derive Jason.Encoder
  defstruct [
    # Event Identity
    event_id: nil,
    pattern_id: nil,

    # Transfer Context
    source_project: nil,
    target_project: nil,
    source_domain: nil,
    target_domain: nil,

    # Outcome
    success: false,
    fitness_delta: 0.0,        # Change in pattern fitness after transfer

    # Temporal
    generation: 0,
    epoch_id: nil,
    timestamp: nil
  ]

  @typedoc "Transfer event structure"
  @type t :: %__MODULE__{
          event_id: String.t() | nil,
          pattern_id: String.t() | nil,
          source_project: String.t() | nil,
          target_project: String.t() | nil,
          source_domain: String.t() | nil,
          target_domain: String.t() | nil,
          success: boolean(),
          fitness_delta: float(),
          generation: non_neg_integer(),
          epoch_id: String.t() | nil,
          timestamp: DateTime.t() | nil
        }

  @doc """
  Execute a transfer attempt of a pattern from one project to another.

  ## Parameters

  - `pattern` — Pattern being transferred
  - `source_project` — Project where pattern was discovered
  - `target_project` — Project receiving the pattern
  - `success?` — Whether transfer succeeded
  - `fitness_delta` — Change in fitness (positive = improved, negative = degraded)
  - `generation` — Current generation
  - `epoch_id` — Current epoch

  ## Returns

  - Transfer event record
  """
  def execute(%RepairPattern{} = pattern, source_project, target_project, success?, fitness_delta, generation, epoch_id) do
    now = DateTime.utc_now()

    # Determine domains from project names
    source_domain = extract_domain(source_project)
    target_domain = extract_domain(target_project)

    %__MODULE__{
      event_id: generate_transfer_id(pattern.id),
      pattern_id: pattern.id,
      source_project: source_project,
      target_project: target_project,
      source_domain: source_domain,
      target_domain: target_domain,
      success: success?,
      fitness_delta: Float.round(fitness_delta, 3),
      generation: generation,
      epoch_id: epoch_id,
      timestamp: now
    }
  end

  @doc """
  Detect potential transfer opportunities for a pattern.

  A pattern can transfer if:
  - It has been used in at least 2 different projects already
  - OR it has high transferability score (> 0.6)

  ## Parameters

  - `pattern` — Pattern to evaluate
  - `available_projects` — List of projects that haven't used this pattern yet

  ## Returns

  - List of potential target projects
  """
  def detect_transfer_opportunities(%RepairPattern{} = pattern, available_projects) do
    unique_projects = length(Enum.uniq(pattern.projects_used))

    # Pattern must have proven itself in multiple contexts
    can_transfer = unique_projects >= 2 or pattern.transferability > 0.6

    if can_transfer do
      # Return projects not yet using this pattern
      used_projects = MapSet.new(pattern.projects_used)
      Enum.filter(available_projects, fn project ->
        project not in used_projects
      end)
    else
      []
    end
  end

  @doc """
  Calculate overall transferability metrics.

  ## Parameters

  - `transfer_events` — List of all transfer events

  ## Returns

  - Map of transfer metrics
  """
  def get_metrics(transfer_events) do
    total_transfers = length(transfer_events)

    if total_transfers == 0 do
      %{
        transfer_events: 0,
        transfer_success_rate: 0.0,
        cross_project_transfers: 0,
        cross_domain_transfers: 0,
        avg_fitness_delta: 0.0,
        transferability_score: 0.0
      }
    else
      successful = Enum.count(transfer_events, & &1.success)
      success_rate = successful / total_transfers

      # Count cross-project transfers (different projects)
      cross_project =
        Enum.count(transfer_events, fn event ->
          event.source_project != event.target_project
        end)

      # Count cross-domain transfers (different domains)
      cross_domain =
        Enum.count(transfer_events, fn event ->
          event.source_domain != event.target_domain
        end)

      # Average fitness delta
      avg_delta =
        Enum.sum_by(transfer_events, & &1.fitness_delta) / total_transfers

      # Transferability score: weighted combination
      transferability_score = calculate_transferability_score(success_rate, cross_domain, total_transfers)

      %{
        transfer_events: total_transfers,
        transfer_success_rate: Float.round(success_rate, 3),
        cross_project_transfers: cross_project,
        cross_domain_transfers: cross_domain,
        avg_fitness_delta: Float.round(avg_delta, 3),
        transferability_score: Float.round(transferability_score, 3)
      }
    end
  end

  @doc """
  Calculate transferability score for a pattern based on its transfer history.

  Formula:
  ```
  transferability = 
    (successful_transfers / total_transfers) * 0.5 +
    (cross_domain_transfers / total_transfers) * 0.3 +
    min(avg_fitness_delta, 0) * 0.2
  ```

  ## Parameters

  - `pattern_transfers` — List of transfers for a specific pattern

  ## Returns

  - Transferability score (0.0-1.0)
  """
  def calculate_pattern_transferability(pattern_transfers) do
    total = length(pattern_transfers)

    if total == 0 do
      0.0
    else
      successful = Enum.count(pattern_transfers, & &1.success)
      cross_domain = Enum.count(pattern_transfers, fn t -> t.source_domain != t.target_domain end)
      avg_delta = Enum.sum_by(pattern_transfers, & &1.fitness_delta) / total

      score = (
        (successful / total) * 0.5 +
        (cross_domain / total) * 0.3 +
        max(min(avg_delta + 0.5, 1.0), 0.0) * 0.2
      )

      Float.clamp(score, 0.0, 1.0)
    end
  end

  # Private helpers

  defp generate_transfer_id(pattern_id) do
    "transfer_#{pattern_id}_#{:crypto.strong_rand_bytes(4) |> Base.encode16(case: :lower)}"
  end

  defp extract_domain(project_name) do
    # Extract domain category from project name
    cond do
      String.contains?(project_name, ["api", "rest", "graphql"]) -> :api
      String.contains?(project_name, ["auth", "oauth", "security"]) -> :security
      String.contains?(project_name, ["store", "cache", "database", "kv"]) -> :storage
      String.contains?(project_name, ["worker", "background", "queue"]) -> :async
      String.contains?(project_name, ["web", "frontend", "ui"]) -> :web
      true -> :general
    end
  end

  defp calculate_transferability_score(success_rate, cross_domain_count, total_transfers) do
    # Weighted score emphasizing cross-domain success
    cross_domain_ratio = cross_domain_count / max(1, total_transfers)

    score = (
      success_rate * 0.6 +
      cross_domain_ratio * 0.4
    )

    # Clamp to 0.0-1.0 range (Float.clamp not available in Elixir 1.18.4)
    max(0.0, min(1.0, score))
  end
end
