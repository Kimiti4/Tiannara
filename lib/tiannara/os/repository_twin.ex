defmodule TiannaraOS.RepositoryTwin do
  @moduledoc """
  Manages stateful, persistent Repository Worlds inside TiannaraOS.
  Provides simulated Git branch checkouts, commits, PR merges, issue trackers,
  historical event logs, and CI pipelines that output EvidenceNodes.
  """

  require Logger
  alias TiannaraOS.EvidenceNode

  @derive Jason.Encoder
  defstruct [
    :id,                  # atom() - unique identifier
    :name,                # String.t() - repository name
    :path,                # String.t() - path in scratch/
    commits: [],          # list(map) - [%{sha: "...", author: "...", message: "...", timestamp: DateTime.t()}]
    pull_requests: [],    # list(map) - [%{id: integer(), title: "...", source_branch: "...", target_branch: "...", status: :open | :merged | :closed}]
    artifacts: %{
      dependencies: %{},
      source_files: %{},
      test_files: %{},
      configs: %{}
    },
    issues: [],           # list(map) - [%{id: integer(), title: "...", status: :open | :closed}]
    ci_runs: [],          # list(map) - [%{sha: "...", outcome: :success | :failure, evidence_id: atom(), run_at: DateTime.t()}]
    world_events: [],     # list(map) - [%{type: atom(), message: String.t(), timestamp: DateTime.t()}]
    branches: %{"main" => "root_sha"}, # map(string => string) - branch reference map
    current_branch: "main",
    discoveries: [],      # list(atom()) - discovery reference IDs
    metrics: %{
      commits: 0,
      vulnerabilities_found: 0,
      vulnerabilities_fixed: 0,
      ci_success_rate: 0.0,
      discoveries_generated: 0
    },
    metadata: %{}
  ]

  @type t :: %__MODULE__{
    id: atom(),
    name: String.t(),
    path: String.t(),
    commits: [map()],
    pull_requests: [map()],
    artifacts: map(),
    issues: [map()],
    ci_runs: [map()],
    world_events: [map()],
    branches: %{String.t() => String.t()},
    current_branch: String.t(),
    discoveries: [atom()],
    metrics: map(),
    metadata: map()
  }

  @doc """
  Initializes a stateful repository twin on disk and in memory.
  """
  def create_twin(id_or_name, name_or_file_map, artifacts \\ %{}, opts \\ [])

  # Legacy 2-argument format support: create_twin(name, file_map) -> returns {:ok, twin_path}
  def create_twin(name, file_map, _artifacts, _opts) when is_binary(name) and is_map(file_map) do
    unique_id = System.unique_integer([:positive])
    scratch_dir = Path.expand("scratch", File.cwd!())
    twin_path = Path.join([scratch_dir, "repo_world_#{name}_#{unique_id}"])

    case File.mkdir_p(twin_path) do
      :ok ->
        Enum.each(file_map, fn {file_name, content} ->
          full_file_path = Path.join(twin_path, file_name)
          File.mkdir_p!(Path.dirname(full_file_path))
          File.write!(full_file_path, content)
        end)
        Logger.info("📂 [Repository World] Setup successful (legacy signature) for #{name} at #{twin_path}")
        {:ok, twin_path}

      {:error, reason} ->
        {:error, reason}
    end
  end

  # New stateful format: create_twin(id, name, artifacts, opts) -> returns {:ok, %RepositoryTwin{}}
  def create_twin(id, name, artifacts, opts) when is_atom(id) and is_binary(name) do
    unique_id = System.unique_integer([:positive])
    scratch_dir = Path.expand("scratch", File.cwd!())
    twin_path = Path.join([scratch_dir, "repo_world_#{name}_#{unique_id}"])

    case File.mkdir_p(twin_path) do
      :ok ->
        # Format artifacts map with default keys
        full_artifacts = %{
          dependencies: Map.get(artifacts, :dependencies, %{}),
          source_files: Map.get(artifacts, :source_files, %{}),
          test_files: Map.get(artifacts, :test_files, %{}),
          configs: Map.get(artifacts, :configs, %{})
        }

        # Setup files on disk
        write_artifacts_to_disk(twin_path, full_artifacts)

        root_sha = "sha_root_#{unique_id}"
        now = DateTime.utc_now()

        initial_commit = %{
          sha: root_sha,
          author: "system",
          message: "Initial repository setup",
          timestamp: now
        }

        initial_event = %{
          type: :repository_initialized,
          message: "Repository World #{name} initialized.",
          timestamp: now
        }

        twin = %__MODULE__{
          id: id,
          name: name,
          path: twin_path,
          commits: [initial_commit],
          artifacts: full_artifacts,
          branches: %{"main" => root_sha},
          current_branch: "main",
          world_events: [initial_event],
          metrics: %{
            commits: 1,
            vulnerabilities_found: opts[:vulnerabilities_found] || 0,
            vulnerabilities_fixed: 0,
            ci_success_rate: 1.0,
            discoveries_generated: 0
          }
        }

        Logger.info("📂 [Repository World] Setup successful for #{name} at #{twin_path}")
        {:ok, twin}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Appends commit metadata, updates specific target files on disk, and logs the event.
  """
  @spec commit_changes(t(), String.t(), String.t(), map()) :: t()
  def commit_changes(%__MODULE__{} = twin, author, message, file_updates) do
    # 1. Update files on disk
    Enum.each(file_updates, fn {file_name, content} ->
      full_path = Path.join(twin.path, file_name)
      File.mkdir_p!(Path.dirname(full_path))
      File.write!(full_path, content)
    end)

    # 2. Update memory state
    new_source_files = Map.merge(twin.artifacts.source_files, file_updates)
    updated_artifacts = %{twin.artifacts | source_files: new_source_files}

    sha = "sha_commit_#{System.unique_integer([:positive])}"
    now = DateTime.utc_now()

    new_commit = %{
      sha: sha,
      author: author,
      message: message,
      timestamp: now
    }

    new_event = %{
      type: :commit,
      message: "Commit #{sha} by #{author}: #{message}",
      timestamp: now
    }

    updated_branches = Map.put(twin.branches, twin.current_branch, sha)
    updated_metrics = %{twin.metrics | commits: twin.metrics.commits + 1}

    %__MODULE__{
      twin |
      commits: twin.commits ++ [new_commit],
      artifacts: updated_artifacts,
      branches: updated_branches,
      world_events: twin.world_events ++ [new_event],
      metrics: updated_metrics
    }
  end

  @doc """
  Registers a new branch in the Git metadata.
  """
  @spec create_branch(t(), String.t()) :: t()
  def create_branch(%__MODULE__{} = twin, branch_name) do
    head_sha = Map.get(twin.branches, twin.current_branch, "root_sha")
    updated_branches = Map.put(twin.branches, branch_name, head_sha)
    now = DateTime.utc_now()

    new_event = %{
      type: :branch_created,
      message: "Branch #{branch_name} created from #{twin.current_branch}.",
      timestamp: now
    }

    %__MODULE__{
      twin |
      branches: updated_branches,
      world_events: twin.world_events ++ [new_event]
    }
  end

  @doc """
  Simulates a checkout branch context switch.
  """
  @spec checkout_branch(t(), String.t()) :: t()
  def checkout_branch(%__MODULE__{} = twin, branch_name) do
    if Map.has_key?(twin.branches, branch_name) do
      now = DateTime.utc_now()
      new_event = %{
        type: :branch_checkout,
        message: "Switched to branch #{branch_name}.",
        timestamp: now
      }

      %__MODULE__{twin | current_branch: branch_name, world_events: twin.world_events ++ [new_event]}
    else
      twin
    end
  end

  @doc """
  Opens a new Pull Request.
  """
  @spec open_pull_request(t(), String.t(), String.t(), String.t()) :: t()
  def open_pull_request(%__MODULE__{} = twin, title, source_branch, target_branch) do
    pr_id = length(twin.pull_requests) + 1
    new_pr = %{
      id: pr_id,
      title: title,
      source_branch: source_branch,
      target_branch: target_branch,
      status: :open
    }

    now = DateTime.utc_now()
    new_event = %{
      type: :pr_opened,
      message: "PR ##{pr_id} opened: #{title} (#{source_branch} -> #{target_branch}).",
      timestamp: now
    }

    %__MODULE__{
      twin |
      pull_requests: twin.pull_requests ++ [new_pr],
      world_events: twin.world_events ++ [new_event]
    }
  end

  @doc """
  Simulates merging a pull request.
  """
  @spec merge_pull_request(t(), integer(), String.t()) :: t()
  def merge_pull_request(%__MODULE__{} = twin, pr_id, author \\ "system") do
    case Enum.find(twin.pull_requests, &(&1.id == pr_id)) do
      nil ->
        twin

      pr ->
        if pr.status == :open do
          # Mark merged
          updated_prs =
            Enum.map(twin.pull_requests, fn
              p when p.id == pr_id -> %{p | status: :merged}
              p -> p
            end)

          now = DateTime.utc_now()
          sha = "sha_merge_#{System.unique_integer([:positive])}"

          merge_commit = %{
            sha: sha,
            author: author,
            message: "Merge pull request ##{pr_id} from #{pr.source_branch}",
            timestamp: now
          }

          new_event = %{
            type: :pr_merged,
            message: "PR ##{pr_id} merged into #{pr.target_branch}.",
            timestamp: now
          }

          updated_branches = 
            twin.branches
            |> Map.put(pr.target_branch, sha)
            |> Map.put(pr.source_branch, sha)

          # Increment metrics commits
          updated_metrics = %{
            twin.metrics |
            commits: twin.metrics.commits + 1,
            vulnerabilities_fixed: twin.metrics.vulnerabilities_fixed + 1
          }

          %__MODULE__{
            twin |
            pull_requests: updated_prs,
            commits: twin.commits ++ [merge_commit],
            branches: updated_branches,
            world_events: twin.world_events ++ [new_event],
            metrics: updated_metrics
          }
        else
          twin
        end
    end
  end

  @doc """
  Opens an issue.
  """
  @spec open_issue(t(), String.t()) :: t()
  def open_issue(%__MODULE__{} = twin, title) do
    issue_id = length(twin.issues) + 1
    new_issue = %{
      id: issue_id,
      title: title,
      status: :open
    }

    now = DateTime.utc_now()
    new_event = %{
      type: :issue_opened,
      message: "Issue ##{issue_id} opened: #{title}",
      timestamp: now
    }

    %__MODULE__{
      twin |
      issues: twin.issues ++ [new_issue],
      world_events: twin.world_events ++ [new_event]
    }
  end

  @doc """
  Closes an issue.
  """
  @spec close_issue(t(), integer()) :: t()
  def close_issue(%__MODULE__{} = twin, issue_id) do
    updated_issues =
      Enum.map(twin.issues, fn
        issue when issue.id == issue_id -> %{issue | status: :closed}
        issue -> issue
      end)

    now = DateTime.utc_now()
    new_event = %{
      type: :issue_closed,
      message: "Issue ##{issue_id} closed.",
      timestamp: now
    }

    %__MODULE__{
      twin |
      issues: updated_issues,
      world_events: twin.world_events ++ [new_event]
    }
  end

  @doc """
  Runs a simulated CI pipeline on disk files, returning an EvidenceNode
  and logging pipeline outcomes.
  """
  @spec run_ci_pipeline(t(), atom()) :: {:ok, t(), EvidenceNode.t()}
  def run_ci_pipeline(%__MODULE__{} = twin, world_id) do
    # Scan files on disk for test failures
    mix_exs_path = Path.join(twin.path, "mix.exs")
    
    ci_outcome =
      if File.exists?(mix_exs_path) do
        mix_content = File.read!(mix_exs_path)
        # If mix.exs has plug vulnerable version, CI is failure
        # In multi-language we also scan for vulnerable version syntax
        if String.contains?(mix_content, "{:plug, \"1.13.0\"}") or String.contains?(mix_content, "{:plug, \"~> 1.10.0\"}") do
          :failure
        else
          :success
        end
      else
        # If no mix.exs is present, check test_files outcomes
        test_files_failed =
          twin.artifacts.test_files
          |> Map.values()
          |> Enum.any?(fn content -> String.contains?(content, "assert false") end)

        if test_files_failed, do: :failure, else: :success
      end

    now = DateTime.utc_now()
    evidence_id = String.to_atom("ev_ci_#{twin.id}_#{System.unique_integer([:positive])}")
    
    # Successful CI is value 1.0 (verified healthy), failure is 0.0
    evidence_value = if ci_outcome == :success, do: 1.0, else: 0.0

    evidence_node = %EvidenceNode{
      id: evidence_id,
      type: :evidence,
      name: "CI Pipeline run for #{twin.name}",
      value: evidence_value,
      validity: :valid,
      metadata: %{
        source: :ci_pipeline,
        genome_id: nil,
        execution_backend: :ci_runner,
        target_world: world_id,
        ci_outcome: ci_outcome,
        provenance: ["ci_pipeline_execution"],
        confidence_history: [%{value: evidence_value, updated_at: now}],
        last_updated_at: now
      }
    }

    head_sha = Map.get(twin.branches, twin.current_branch, "root_sha")
    
    ci_run = %{
      sha: head_sha,
      outcome: ci_outcome,
      evidence_id: evidence_id,
      run_at: now
    }

    event_type = if ci_outcome == :success, do: :ci_passed, else: :ci_failed
    new_event = %{
      type: event_type,
      message: "CI Pipeline finished on #{head_sha}: #{to_string(ci_outcome)}.",
      timestamp: now
    }

    # Recalculate metrics success rate
    all_runs = twin.ci_runs ++ [ci_run]
    success_count = Enum.count(all_runs, &(&1.outcome == :success))
    new_rate = success_count / length(all_runs)

    updated_metrics = %{twin.metrics | ci_success_rate: new_rate}

    updated_twin = %__MODULE__{
      twin |
      ci_runs: all_runs,
      world_events: twin.world_events ++ [new_event],
      metrics: updated_metrics
    }

    {:ok, updated_twin, evidence_node}
  end

  @doc """
  Cleans up repository twin directory layout recursively.
  """
  @spec cleanup_twin(t() | String.t()) :: :ok | {:error, any()}
  def cleanup_twin(%__MODULE__{path: path}), do: cleanup_twin(path)
  def cleanup_twin(path) when is_binary(path) do
    case File.rm_rf(path) do
      {:ok, _paths} -> :ok
      {:error, reason, _path} -> {:error, reason}
    end
  end

  # --- PRIVATE HELPERS ---

  defp write_artifacts_to_disk(path, artifacts) do
    # 1. Write configs
    Enum.each(artifacts.configs, fn {file, content} ->
      full = Path.join(path, file)
      File.mkdir_p!(Path.dirname(full))
      File.write!(full, content)
    end)

    # 2. Write source files
    Enum.each(artifacts.source_files, fn {file, content} ->
      full = Path.join(path, file)
      File.mkdir_p!(Path.dirname(full))
      File.write!(full, content)
    end)

    # 3. Write test files
    Enum.each(artifacts.test_files, fn {file, content} ->
      full = Path.join(path, file)
      File.mkdir_p!(Path.dirname(full))
      File.write!(full, content)
    end)

    # 4. Generate mix.exs from dependencies if not already manually written
    mix_exs_path = Path.join(path, "mix.exs")
    unless File.exists?(mix_exs_path) or map_size(artifacts.dependencies) == 0 do
      deps_string =
        artifacts.dependencies
        |> Enum.map(fn {pkg, ver} -> "{:#{pkg}, \"#{ver}\"}" end)
        |> Enum.join(",\n      ")

      mix_content = """
      defmodule Simulated.MixProject do
        use Mix.Project
        def project do
          [deps: [
            #{deps_string}
          ]]
        end
      end
      """
      File.write!(mix_exs_path, mix_content)
    end
  end
end
