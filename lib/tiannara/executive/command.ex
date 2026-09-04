defmodule Tiannara.Executive.Command do
  @moduledoc """
  State change requests for the Executive Memory Coordinator.

  Commands are submitted, approved/rejected via consensus,
  and executed by the Executive Memory.
  """

  defstruct [:id, :action, :arguments, :status, :submitted_by, :submitted_at, :approved_by, :executed_at, :error]

  @type status :: :pending | :approved | :rejected | :executed | :failed

  @type t :: %__MODULE__{
    id: String.t(),
    action: atom(),
    arguments: map(),
    status: status(),
    submitted_by: String.t(),
    submitted_at: DateTime.t(),
    approved_by: [String.t()],
    executed_at: DateTime.t() | nil,
    error: String.t() | nil
  }

  @doc "Creates a new command."
  def new(action, arguments, submitted_by \\ "system") do
    %__MODULE__{
      id: Tiannara.Executive.Types.new_id(),
      action: action,
      arguments: arguments,
      status: :pending,
      submitted_by: submitted_by,
      submitted_at: DateTime.utc_now(),
      approved_by: [],
      executed_at: nil,
      error: nil
    }
  end

  @doc "Approves a command."
  def approve(%__MODULE__{} = cmd, approver \\ "system") do
    %{cmd | status: :approved, approved_by: cmd.approved_by ++ [approver]}
  end

  @doc "Rejects a command."
  def reject(%__MODULE__{} = cmd, reason \\ "rejected") do
    %{cmd | status: :rejected, error: reason}
  end

  @doc "Marks a command as executed."
  def mark_executed(%__MODULE__{} = cmd) do
    %{cmd | status: :executed, executed_at: DateTime.utc_now()}
  end

  @doc "Marks a command as failed."
  def mark_failed(%__MODULE__{} = cmd, reason) do
    %{cmd | status: :failed, error: reason}
  end
end
