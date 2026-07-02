defmodule Tiannara.ASC.Reality.RealityBridge do
  @moduledoc """
  Phase 8B: The OS-level interface for Reality Anchoring.
  Clones the repository to a physically isolated temporary directory
  to guarantee execution safety.
  """
  
  require Logger
  alias Tiannara.ASC.Reality.{PatchProposal, EngineeringOutcome}

  @source_repo File.cwd!()

  def setup_sandbox(proposal_id) do
    tmp_base = System.tmp_dir!() || "/tmp"
    sandbox_dir = Path.join(tmp_base, "tiannara_exp_#{proposal_id}")
    
    # Ensure clean directory
    File.rm_rf(sandbox_dir)
    
    Logger.info("🌿 [RealityBridge] Creating isolated physical sandbox at #{sandbox_dir}")
    
    # Clone the repo locally
    {_, 0} = System.cmd("git", ["clone", @source_repo, sandbox_dir], stderr_to_stdout: true)
    
    # Create experiment branch
    branch_name = "sandbox_#{proposal_id}"
    {_, 0} = System.cmd("git", ["checkout", "-b", branch_name], cd: sandbox_dir, stderr_to_stdout: true)
    
    sandbox_dir
  end

  def apply_proposal(sandbox_dir, %PatchProposal{} = proposal) do
    full_path = Path.join(sandbox_dir, proposal.target_file)
    content = File.read!(full_path)
    
    # Replace the target pattern with the new content
    new_content = String.replace(content, proposal.target_pattern, proposal.replacement_content)
    
    File.write!(full_path, new_content)
    Logger.info("📝 [RealityBridge] Applied PatchProposal to #{proposal.target_file} in sandbox")
    :ok
  end

  def compile_and_test(sandbox_dir) do
    Logger.info("🧪 [RealityBridge] Recompiling and executing `mix test` in sandbox...")
    
    # We must ensure dependencies are fetched if needed, but since it's a local clone
    # we might need to fetch or just use the local cache. mix deps.get is safe.
    System.cmd("mix", ["deps.get"], cd: sandbox_dir)
    
    # Compile
    {compile_out, compile_code} = System.cmd("mix", ["compile"], cd: sandbox_dir, stderr_to_stdout: true)
    
    if compile_code != 0 do
      Logger.error("❌ [RealityBridge] Compilation failed in sandbox:\n#{compile_out}")
      %{compilation_success: false, tests_passed: false, coverage: 0.0}
    else
      # Test
      {test_out, test_code} = System.cmd("mix", ["test", "--cover"], cd: sandbox_dir, stderr_to_stdout: true)
      
      coverage = parse_coverage(test_out)
      
      %{
        compilation_success: true,
        tests_passed: test_code == 0,
        coverage: coverage
      }
    end
  end

  def benchmark_sandbox(sandbox_dir, benchmark_module) do
    # Run a specific benchmark inside the sandbox
    # We do this by spawning Elixir via system cmd to evaluate the benchmark in the new compiled context
    Logger.info("⏱️ [RealityBridge] Executing benchmark in sandbox...")
    
    eval_str = """
    {time, _} = :timer.tc(fn -> #{benchmark_module}.benchmark() end)
    IO.puts("BENCHMARK_MS=\#{time}")
    """
    
    {out, _} = System.cmd("mix", ["run", "-e", eval_str], cd: sandbox_dir, stderr_to_stdout: true)
    
    case Regex.run(~r/BENCHMARK_MS=(\d+)/, out) do
      [_, time_str] -> String.to_integer(time_str)
      _ -> 
        Logger.error("Failed to parse benchmark time from sandbox. Output: #{out}")
        999_999_999
    end
  end

  def commit_to_mainline(sandbox_dir, branch_name, commit_msg) do
    # Push the sandbox branch back to the main repo and merge it
    Logger.info("✅ [RealityBridge] Merging successful experiment into mainline")
    
    System.cmd("git", ["add", "."], cd: sandbox_dir)
    System.cmd("git", ["commit", "-m", commit_msg], cd: sandbox_dir)
    
    # Push back to origin (which is our main repo)
    System.cmd("git", ["push", "origin", branch_name], cd: sandbox_dir)
    
    # In the main repo, merge it
    System.cmd("git", ["merge", branch_name], cd: @source_repo)
    System.cmd("git", ["branch", "-D", branch_name], cd: @source_repo)
    
    # Clean up sandbox
    File.rm_rf(sandbox_dir)
    :ok
  end

  def rollback_sandbox(sandbox_dir) do
    Logger.warning("🗑️ [RealityBridge] Discarding sandbox.")
    File.rm_rf(sandbox_dir)
    :ok
  end

  defp parse_coverage(output) do
    case Regex.run(~r/(\d+\.\d+)%/, output) do
      [_, pct] -> String.to_float(pct) / 100.0
      _ -> 0.0
    end
  end
end
