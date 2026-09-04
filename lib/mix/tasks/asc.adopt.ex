defmodule Mix.Tasks.Asc.Adopt do
  @moduledoc """
  Controlled two-key adoption of an ASC mission candidate into production.

  Two keys are required:

    1. machine evidence — the mission `priv/asc/missions/<mission>/knowledge.eterm`
       must carry verdict `:accept_eligible` with the candidate on the front
    2. human authorization — a `priv/asc/authorizations/*.human` artifact
       verified by `Tiannara.ASC.Adoption.Gate`

  Always run `--dry-run` first and confirm the reported scope is exactly the
  declared file(s). Execution is bounded to that scope, snapshots pre-adoption
  state, validates compile + scoped tests + watchdog-protected boot, and rolls
  back automatically on any failure.
  """
  use Mix.Task

  @shortdoc "Controlled two-key adoption of an ASC candidate"

  @impl true
  def run(args) do
    {opts, _, invalid} =
      OptionParser.parse(args,
        strict: [
          mission: :string,
          candidate: :string,
          branch: :string,
          files: :keep,
          authorization: :string,
          dry_run: :boolean
        ],
        aliases: [d: :dry_run]
      )

    cond do
      invalid != [] ->
        Mix.shell().error("ABORTED: unrecognized arguments: #{inspect(invalid)}")
        exit({:shutdown, 1})

      is_nil(opts[:candidate]) ->
        Mix.shell().error("ABORTED: --candidate is required")
        exit({:shutdown, 1})

      is_nil(opts[:branch]) ->
        Mix.shell().error("ABORTED: --branch is required")
        exit({:shutdown, 1})

      is_nil(opts[:authorization]) ->
        Mix.shell().error("ABORTED: --authorization is required")
        exit({:shutdown, 1})

      Keyword.get_values(opts, :files) == [] ->
        Mix.shell().error("ABORTED: at least one --files path is required")
        exit({:shutdown, 1})

      true ->
        Tiannara.ASC.Adoption.Adopter.adopt(%{
          mission: opts[:mission] || "ASC-AE-003",
          candidate: opts[:candidate],
          branch: opts[:branch],
          files: Keyword.get_values(opts, :files),
          authorization: opts[:authorization],
          dry_run: Keyword.get(opts, :dry_run, false)
        })
    end
  end
end