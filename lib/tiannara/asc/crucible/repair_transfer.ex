defmodule Tiannara.ASC.Crucible.RepairTransfer do
  @moduledoc """
  Repair Transfer — tracks cross-project repair movement and transferability.

  Records when a repair pattern discovered in one project is successfully
  applied in another project, enabling measurement of knowledge transferability.

  ## Persistence

  Stores transfers in: data/repair_transfers.ndjson

  ## Example

      iex> transfer = %Tiannara.ASC.Crucible.RepairTransfer{
      ...>   source_project: "web_app_001",
      ...>   target_project: "api_001",
      ...>   repair_pattern_id: "pattern_abc123",
      ...>   success: true
      ...> }

  """

  @derive Jason.Encoder
  defstruct [
    # Identity
    id: nil,

    # Transfer tracking
    source_project: nil,        # Project where pattern was discovered
    target_project: nil,        # Project where pattern was reused
    repair_pattern_id: nil,     # ID of transferred repair pattern

    # Outcome
    success: false,             # Was transfer successful?
    timestamp: nil              # When transfer occurred
  ]

  @typedoc "Repair transfer record"
  @type t :: %__MODULE__{
          id: String.t() | nil,
          source_project: String.t() | nil,
          target_project: String.t() | nil,
          repair_pattern_id: String.t() | nil,
          success: boolean(),
          timestamp: DateTime.t() | nil
        }

  # Persistence file
  @persistence_file "data/repair_transfers.ndjson"

  @doc """
  Record a repair transfer between projects.

  ## Parameters

  - `source_project` — Project where pattern was originally discovered
  - `target_project` — Project where pattern was reused
  - `pattern_id` — ID of the repair pattern being transferred
  - `success?` — Whether the transfer was successful

  ## Returns

  - Created RepairTransfer struct
  """
  def record_transfer(source_project, target_project, pattern_id, success?) do
    now = DateTime.utc_now()

    transfer = %__MODULE__{
      id: generate_transfer_id(),
      source_project: source_project,
      target_project: target_project,
      repair_pattern_id: pattern_id,
      success: success?,
      timestamp: now
    }

    # Persist transfer
    persist_transfer(transfer)

    IO.puts("     📤 Transfer recorded: #{source_project} → #{target_project} (#{if success?, do: "SUCCESS", else: "FAILED"})")

    transfer
  end

  @doc """
  Get all recorded transfers.

  ## Returns

  - List of RepairTransfer structs
  """
  def get_all_transfers do
    if File.exists?(@persistence_file) do
      @persistence_file
      |> File.read!()
      |> String.split("\n", trim: true)
      |> Enum.map(&Jason.decode!/1)
      |> Enum.map(&struct(__MODULE__, &1))
    else
      []
    end
  end

  @doc """
  Calculate transfer success rate.

  ## Returns

  - Float between 0.0 and 1.0
  """
  def transfer_success_rate do
    transfers = get_all_transfers()

    if length(transfers) == 0 do
      0.0
    else
      successes = Enum.count(transfers, & &1.success)
      successes / length(transfers)
    end
  end

  @doc """
  Get transfer count.

  ## Returns

  - Integer count of transfers
  """
  def transfer_count do
    length(get_all_transfers())
  end

  # Private helpers

  defp generate_transfer_id do
    "transfer_#{:crypto.strong_rand_bytes(8) |> Base.encode16(case: :lower)}"
  end

  defp persist_transfer(transfer) do
    # Ensure data directory exists
    File.mkdir_p!(Path.dirname(@persistence_file))

    # Append transfer as NDJSON line
    json_line = Jason.encode!(Map.from_struct(transfer))
    File.write!(@persistence_file, json_line <> "\n", [:append])
  end
end
