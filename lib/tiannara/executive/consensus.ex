defmodule Tiannara.Executive.Consensus do
  @moduledoc """
  Consensus evaluation for Executive Memory commands.

  Supports four modes:
  - `:simple` — single-validator approval
  - `:majority` — requires >50% of validators to approve
  - `:constitutional` — requires 100% of validators to approve
  - `:emergency` — bypasses consensus, logged and audited
  """

  require Logger

  alias Tiannara.Executive.Command

  @doc """
  Evaluates a command using the specified consensus mode.
  Returns `:approved` or `{:error, reason}`.
  """
  def evaluate(%Command{} = cmd, mode \\ :simple) do
    case mode do
      :simple -> simple_consensus(cmd)
      :majority -> majority_consensus(cmd)
      :constitutional -> constitutional_consensus(cmd)
      :emergency -> emergency_consensus(cmd)
    end
  end

  defp simple_consensus(%Command{action: action} = _cmd) do
    case action do
      :gc -> {:error, "GC requires majority consensus"}
      a when a in [:compact, :rebuild] -> {:error, "Destructive operations require majority consensus"}
      _ -> :approved
    end
  end

  defp majority_consensus(%Command{} = cmd) do
    validators = get_validators()
    votes = Enum.map(validators, fn v -> v.(cmd) end)
    approvals = Enum.count(votes, fn v -> v == :approve end)
    total = length(votes)

    if approvals > total / 2 do
      :approved
    else
      {:error, "Majority consensus failed: #{approvals}/#{total} approved"}
    end
  end

  defp constitutional_consensus(%Command{} = cmd) do
    validators = get_validators()
    votes = Enum.map(validators, fn v -> v.(cmd) end)
    approvals = Enum.count(votes, fn v -> v == :approve end)
    total = length(votes)

    if approvals == total do
      :approved
    else
      {:error, "Constitutional consensus failed: #{approvals}/#{total} approved (unanimous required)"}
    end
  end

  defp emergency_consensus(%Command{} = cmd) do
    Logger.warning("[ExecutiveMemory] Emergency consensus bypass for command: #{cmd.id}")
    :approved
  end

  defp get_validators do
    validators = Application.get_env(:tiannara, :executive_memory, [])
               |> Keyword.get(:validators, [])

    if validators == [] do
      [fn _ -> :approve end]
    else
      validators
    end
  end
end
