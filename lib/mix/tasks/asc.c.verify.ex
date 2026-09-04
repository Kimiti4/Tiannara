defmodule Mix.Tasks.Asc.C.Verify do
  @moduledoc """
  Statistical re-verification of the accepted ASC-AE-001 candidate
  (append-only addendum; never rewrites the C6 verdict).

  Usage:
    mix asc.c.verify --rounds 15 --candidate asc-ae001-d1_parallel_boot
  """

  use Mix.Task

  @shortdoc "Verify D1 candidate under repeated paired measurement"

  @impl true
  def run(args) do
    {opts, _, _} = OptionParser.parse(args, strict: [rounds: :integer, candidate: :string])

    Tiannara.ASC.CMissions.Verification.run(
      rounds: opts[:rounds] || 15,
      candidate_branch: opts[:candidate] || "asc-ae001-d1_parallel_boot"
    )
  end
end