defmodule Tiannara.ASC.Adoption.Adopter do
  @moduledoc """
  Controlled two-key production adoption for ASC mission candidates.

  Constitutional boundary: ASC establishes eligibility; only a human
  authorization artifact converts eligibility into production change.
  This tool executes exactly what the two keys authorize and nothing else.

  Two keys, both required:

    1. Machine evidence — the mission `knowledge.eterm` must carry
       `verdict: :accept_eligible` and the candidate on the measured `front`.
    2. Human authorization — an artifact verified by
       `Tiannara.ASC.Adoption.Gate` (exact fields, `DECISION:
       AUTHORIZE_ADOPTION`, no placeholders, ISO date).

  Execution controls:

    * scope check — the declared `--files` must equal exactly the diff of
      `HEAD...<branch>` (one production file for AE-003)
    * rollback snapshot — pre-adoption copies of the declared files are
      saved and a `asc-pre-adoption-<mission>` tag is created BEFORE any
      change (the tag anchors lineage; the file copies are the byte-exact
      rollback state)
    * post-adoption validation — compile, scoped test suite, watchdog-
      protected boot smoke; any failure rolls back automatically
    * on success — `asc-adopted-<mission>` tag and an adoption record in
      `priv/asc/adoptions/<mission>-adoption.eterm`

  Dry-run first: nothing is written, no tags, no changes.
  """

  alias Tiannara.ASC.Adoption.Gate

  @evidence_verdict :accept_eligible
  @compile_timeout 1_200_000
  @test_timeout 2_400_000
  @boot_timeout 360_000
  @boot_watchdog_ms 300_000

  def adopt(opts) do
    mission = Map.get(opts, :mission, "ASC-AE-003")
    candidate = Map.fetch!(opts, :candidate)
    branch = Map.fetch!(opts, :branch)
    declared = opts |> Map.get(:files, []) |> Enum.map(&normalize_path/1) |> Enum.sort()
    authorization = Map.fetch!(opts, :authorization)
    dry_run? = Map.get(opts, :dry_run, false)

    with {:ok, fields} <- Gate.verify(authorization),
         :ok <- keys_agree(fields, mission, candidate, branch),
         :ok <- evidence_agrees(mission, candidate),
         :ok <- on_production_line(),
         :ok <- branch_exists(branch),
         {:ok, scope} <- scope_of(branch),
         :ok <- scope_matches(declared, scope) do
      IO.puts("[adopt] Preflight passed. Scope: #{inspect(scope)}")
      IO.puts("[adopt] Keys agreed: evidence #{@evidence_verdict} + human artifact")
      IO.puts("[adopt] Branch: #{branch} | Candidate: #{candidate} | Mission: #{mission}")

      if dry_run? do
        IO.puts("DRY RUN complete. Nothing was changed.")
        :ok
      else
        execute(mission, candidate, branch, scope, authorization)
      end
    else
      {:error, reason} -> abort(reason)
    end
  end

  defp normalize_path(path), do: path |> String.replace("\\", "/") |> String.trim_leading("/")

  defp keys_agree(fields, mission, candidate, branch) do
    cond do
      fields["MISSION"] != mission -> {:error, {:artifact_mission_mismatch, fields["MISSION"], mission}}
      fields["CANDIDATE"] != candidate -> {:error, {:artifact_candidate_mismatch, fields["CANDIDATE"], candidate}}
      fields["BRANCH"] != branch -> {:error, {:artifact_branch_mismatch, fields["BRANCH"], branch}}
      true -> :ok
    end
  end

  defp evidence_agrees(mission, candidate) do
    path = Path.join(["priv", "asc", "missions", mission, "knowledge.eterm"])

    cond do
      not File.exists?(path) ->
        {:error, {:evidence_missing, path}}

      true ->
        case :erlang.binary_to_term(File.read!(path)) do
          %{verdict: @evidence_verdict, front: front} when is_list(front) ->
            on_front? = Enum.any?(front, &(to_string(&1) == candidate))

            if on_front? do
              :ok
            else
              {:error, {:candidate_not_on_front, candidate, front}}
            end

          other ->
            {:error, {:evidence_shape_unexpected, other}}
        end
    end
  end

  defp on_production_line do
    case System.cmd("git", ["branch", "--show-current"], stderr_to_stdout: true) do
      {"main\n", 0} -> :ok
      {out, _} -> {:error, {:not_on_production_line, String.trim(out)}}
    end
  end

  defp branch_exists(branch) do
    case System.cmd("git", ["rev-parse", "--verify", "--quiet", branch], stderr_to_stdout: true) do
      {_, 0} -> :ok
      _ -> {:error, {:branch_missing, branch}}
    end
  end

  defp scope_of(branch) do
    case System.cmd("git", ["diff", "--name-only", "HEAD...#{branch}"], stderr_to_stdout: true) do
      {out, 0} ->
        scope = out |> String.split("\n") |> Enum.map(&String.trim/1) |> Enum.reject(&(&1 == "")) |> Enum.sort()
        {:ok, scope}

      {err, _} ->
        {:error, {:scope_unknown, String.trim(err)}}
    end
  end

  defp scope_matches(declared, scope) do
    cond do
      declared == [] -> {:error, :no_files_declared}
      scope == [] -> {:error, :empty_scope}
      scope != declared -> {:error, {:scope_mismatch, declared: declared, actual: scope}}
      true -> :ok
    end
  end

  defp execute(mission, candidate, branch, scope, authorization) do
    snapshot_dir = Path.join(["priv", "asc", "adoptions", mission, "pre-adoption"])
    File.mkdir_p!(snapshot_dir)

    saved = Enum.map(scope, fn file -> {file, snapshot_copy(file, snapshot_dir)} end)

    with :ok <- create_rollback_tag(mission),
         :ok <- apply_branch_files(branch, scope),
         {:ok, validation} <- validate_post_adoption(mission) do
      finalize(mission, candidate, branch, scope, saved, authorization, validation)
    else
      {:error, reason} -> rollback(scope, saved, reason)
    end
  end

  defp snapshot_copy(file, snapshot_dir) do
    target = Path.join(snapshot_dir, file |> String.replace(~r{[\\/]}, "_"))
    File.cp!(file, target)
    target
  end

  defp create_rollback_tag(mission) do
    tag = "asc-pre-adoption-#{mission}"

    case System.cmd("git", ["tag", tag, "HEAD"], stderr_to_stdout: true) do
      {_, 0} ->
        IO.puts("[adopt] Rollback tag created: #{tag}")
        :ok

      {err, _} ->
        if String.contains?(err, "already exists") and stale_tag_at_head?(tag) do
          IO.puts("[adopt] Rollback tag reused (stale from prior attempt): #{tag}")
          :ok
        else
          {:error, {:rollback_tag_failed, String.trim(err)}}
        end
    end
  end

  defp stale_tag_at_head?(tag) do
    head = String.trim(to_string(elem(System.cmd("git", ["rev-parse", "HEAD"]), 0)))
    pointed = String.trim(to_string(elem(System.cmd("git", ["rev-parse", tag]), 0)))
    pointed == head and pointed != ""
  end

  defp apply_branch_files(branch, scope) do
    Enum.reduce_while(scope, :ok, fn file, :ok ->
      case System.cmd("git", ["checkout", branch, "--", file], stderr_to_stdout: true) do
        {_, 0} -> {:cont, :ok}
        {err, _} -> {:halt, {:error, {:apply_failed, file, String.trim(err)}}}
      end
    end)
  end

  defp validate_post_adoption(mission) do
    IO.puts("[adopt] Post-adoption validation started (compile, scoped tests, boot smoke)...")

    with {:ok, compile_out} <- run_cmd("mix", ["compile"], @compile_timeout, [{"MIX_ENV", "test"}]),
         {:ok, test_out} <-
           run_cmd(
             "mix",
             ["test", "test/tiannara/asc/crucible", "test/tiannara/asc/core", "--no-start"],
             @test_timeout,
             [{"MIX_ENV", "test"}]
           ),
         {:ok, boot_out} <- boot_smoke(mission) do
      {:ok,
       %{
         compile: {:ok, tail(compile_out)},
         tests: {:ok, tail(test_out)},
         boot_smoke: {:ok, tail(boot_out)}
       }}
    else
      {:error, reason} -> {:error, {:post_validation_failed, reason}}
    end
  end

  defp run_cmd(cmd, args, timeout, env) do
    task = Task.async(fn -> System.cmd(cmd, args, stderr_to_stdout: true, env: env) end)

    case Task.yield(task, timeout) || Task.shutdown(task, :brutal_kill) do
      {:ok, {out, 0}} -> {:ok, out}
      {:ok, {out, code}} -> {:error, {cmd, code, tail(out)}}
      nil -> {:error, {cmd, :timeout, "timed out after #{timeout} ms"}}
      {:exit, reason} -> {:error, {cmd, :exit, reason}}
    end
  end

  defp boot_smoke(mission) do
    script =
      Path.join(
        System.tmp_dir!(),
        "asc_adopt_boot_smoke_#{mission}.exs"
      )

    body = """
    watchdog = spawn(fn ->
      Process.sleep(#{@boot_watchdog_ms})
      IO.puts("BOOT_SMOKE_TIMEOUT")
      System.halt(1)
    end)

    case Tiannara.ASC.Crucible.RepairLibrary.start_link([]) do
      {:ok, _pid} ->
        case :ets.info(:repair_library, :size) do
          :undefined ->
            IO.puts("BOOT_SMOKE_FAIL: repair_library table missing")
            System.halt(1)

          size ->
            IO.puts("BOOT_SMOKE_OK: booted, ets size=\#{size}")
            System.halt(0)
        end

      other ->
        IO.puts("BOOT_SMOKE_FAIL: start_link \#{inspect(other)}")
        System.halt(1)
    end
    """

    File.write!(script, body)

    case run_cmd("mix", ["run", "--no-start", script], @boot_timeout, [{"MIX_ENV", "test"}]) do
      {:ok, out} -> {:ok, out}
      {:error, reason} -> {:error, {:boot_smoke, reason}}
    end
  end

  defp finalize(mission, candidate, branch, scope, saved, authorization, validation) do
    adopted_tag = "asc-adopted-#{mission}"

    System.cmd("git", ["tag", adopted_tag, branch], stderr_to_stdout: true)

    record = %{
      mission: mission,
      candidate: candidate,
      branch: branch,
      scope: scope,
      authorization_file: authorization,
      authorization_sha256: sha256(authorization),
      evidence_file: Path.join(["priv", "asc", "missions", mission, "knowledge.eterm"]),
      pre_adoption_snapshots: Enum.map(saved, fn {f, s} -> {f, s, sha256(s)} end),
      post_validation: validation,
      adopted_at: DateTime.utc_now() |> DateTime.to_iso8601(),
      tags: %{rollback: "asc-pre-adoption-#{mission}", adopted: adopted_tag}
    }

    record_path = Path.join(["priv", "asc", "adoptions", "#{mission}-adoption.eterm"])
    File.mkdir_p!(Path.dirname(record_path))
    File.write!(record_path, :erlang.term_to_binary(record))

    IO.puts("ADOPTION COMPLETE: #{candidate} (#{mission})")
    IO.puts("[adopt] Record: #{record_path}")
    IO.puts("[adopt] Rollback tag: asc-pre-adoption-#{mission} | Adopted tag: #{adopted_tag}")
    :ok
  end

  defp rollback(scope, saved, reason) do
    Enum.each(saved, fn {file, snapshot} ->
      File.cp!(snapshot, file)
    end)

    IO.puts("ROLLBACK: restored #{inspect(scope)} to pre-adoption state")
    IO.puts("ROLLBACK reason: #{inspect(reason)}")
    abort({:rollback_completed, reason})
  end

  defp sha256(path), do: :crypto.hash(:sha256, File.read!(path)) |> Base.encode16(case: :lower)

  defp tail(out, lines \\ 40) do
    out |> String.split("\n") |> Enum.reverse() |> Enum.take(lines) |> Enum.reverse() |> Enum.join("\n")
  end

  defp abort(reason) do
    IO.puts("ABORTED: #{inspect(reason)}")
    exit({:shutdown, 1})
  end
end