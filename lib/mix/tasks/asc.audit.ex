defmodule Mix.Tasks.Asc.Audit do
  @moduledoc "Runs the full ASC test suite through the capability classifier."
  use Mix.Task

  @shortdoc "ASC capability audit (Milestone B classifier)"

  @impl true
  def run(args) do
    {opts, rest, _} =
      OptionParser.parse(args, strict: [manifest: :string, out: :string, no_start: :boolean])

    System.put_env("ASC_AUDIT_MANIFEST", opts[:manifest] || "test/asc/capability_manifest.exs")
    System.put_env("ASC_AUDIT_OUT", opts[:out] || "priv/audit")

    test_args = ["--formatter", "Tiannara.ASC.Audit.Formatter", "--color"]

    test_args =
      if opts[:no_start], do: ["--no-start" | test_args], else: test_args

    Mix.Task.run("test", test_args ++ rest)
  end
end