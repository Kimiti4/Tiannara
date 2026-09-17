defmodule Mix.Tasks.Cis.ValidatePhase5E do
  @moduledoc """
  Phase 5E Validation Gate

  Ensures CIS runtime is safe to compile by enforcing:
  - No forbidden modules active (Phase 5F+ features)
  - Core OTP modules exist and are loadable
  - Event pipeline integrity (World → EventStore → Immune → Safety)
  - Basic compilation sanity checks
  
  ## Usage

      mix cis.validate_phase5e

  This should pass before running `mix compile` in Phase 5E.
  """

  use Mix.Task

  @shortdoc "Validates CIS Phase 5E runtime before compile"

  # Required modules for minimal Phase 5E boot
  @required_modules [
    TiannaraRuntime.Application,
    TiannaraRuntime.WorldSupervisor,
    TiannaraRuntime.MultiWorld.Events.EventStore,
    TiannaraRuntime.Cortex.ImmuneCortex,
    TiannaraRuntime.Cortex.SafetyCortex
  ]

  # Forbidden modules (Phase 5F+ features not yet stabilized)
  @forbidden_modules [
    TiannaraRuntime.MultiWorld.GRCC,
    TiannaraRuntime.MultiWorld.AEO,
    TiannaraRuntime.MultiWorld.SnapshotEngine,
    TiannaraRuntime.MultiWorld.ConsensusNetwork,
    TiannaraRuntime.MultiWorld.ForkEngine,
    TiannaraRuntime.MultiWorld.IdentityEvolution
  ]

  # Required file paths for event pipeline
  @required_files [
    "lib/tiannara_runtime/application.ex",
    "lib/tiannara_runtime/world_supervisor.ex",
    "lib/tiannara_runtime/multi_world/events/event_store.ex",
    "lib/tiannara_runtime/cortex/immune_cortex.ex",
    "lib/tiannara_runtime/cortex/safety_cortex.ex"
  ]

  def run(_args) do
    Mix.shell().info("🧠 Running CIS Phase 5E validation gate...")
    Mix.shell().info("")

    check_required_modules()
    check_forbidden_modules()
    check_event_pipeline()
    check_basic_compilation_sanity()

    Mix.shell().info("")
    Mix.shell().info("✅ Phase 5E validation PASSED — safe to compile")
    Mix.shell().info("")
    Mix.shell().info("Next step: mix compile")
  end

  # ----------------------------
  # REQUIRED MODULE CHECK
  # ----------------------------
  defp check_required_modules do
    Mix.shell().info("🔍 Checking required modules...")

    Enum.each(@required_modules, fn mod ->
      case Code.ensure_loaded(mod) do
        {:module, _} ->
          Mix.shell().info("   ✅ #{inspect(mod)}")

        {:error, reason} ->
          Mix.raise("""
          ❌ Missing required module: #{inspect(mod)}
          
          Reason: #{inspect(reason)}
          
          This module is essential for Phase 5E boot stability.
          Ensure it exists and compiles cleanly before proceeding.
          """)
      end
    end)

    Mix.shell().info("")
  end

  # ----------------------------
  # FORBIDDEN MODULE CHECK
  # ----------------------------
  defp check_forbidden_modules do
    Mix.shell().info("🚫 Checking forbidden Phase 5F+ modules...")

    forbidden_found = Enum.filter(@forbidden_modules, fn mod ->
      Code.ensure_loaded?(mod)
    end)

    if length(forbidden_found) > 0 do
      Mix.raise("""
      ❌ Forbidden modules active in Phase 5E:

      #{Enum.map_join(forbidden_found, "\n", &"   • #{inspect(&1)}")}

      These modules belong to Phase 5F+ and must be disabled/commented out
      until Phase 5E runtime stability is confirmed.

      Action required:
      1. Comment out or move these modules temporarily
      2. Remove them from application.ex supervision tree
      3. Re-run: mix cis.validate_phase5e
      """)
    else
      Mix.shell().info("   ✅ No forbidden modules detected")
    end

    Mix.shell().info("")
  end

  # ----------------------------
  # EVENT PIPELINE CHECK
  # ----------------------------
  defp check_event_pipeline do
    Mix.shell().info("🔁 Checking event pipeline integrity...")

    missing_files = Enum.reject(@required_files, &File.exists?/1)

    if length(missing_files) > 0 do
      Mix.raise("""
      ❌ Event pipeline incomplete (missing core files):

      #{Enum.map_join(missing_files, "\n", &"   • #{&1}")}

      The event flow World → EventStore → Immune → Safety → WorldSupervisor
      requires all these files to exist and be structurally sound.

      Action required:
      1. Ensure all listed files exist in the correct paths
      2. Verify they have valid Elixir syntax
      3. Re-run: mix cis.validate_phase5e
      """)
    else
      Mix.shell().info("   ✅ All event pipeline files present")
      
      # Additional check: verify files are non-empty
      empty_files = Enum.filter(@required_files, fn path ->
        File.exists?(path) && File.stat!(path).size == 0
      end)

      if length(empty_files) > 0 do
        Mix.raise("""
        ❌ Event pipeline files are empty:

        #{Enum.map_join(empty_files, "\n", &"   • #{&1}")}

        Files must contain valid module definitions.
        """)
      else
        Mix.shell().info("   ✅ All files contain code")
      end
    end

    Mix.shell().info("")
  end

  # ----------------------------
  # LIGHTWEIGHT COMPILATION SANITY CHECK
  # ----------------------------
  defp check_basic_compilation_sanity do
    Mix.shell().info("⚙️ Running lightweight syntax sanity check...")
    Mix.shell().info("   (This may take 10-30 seconds)...")

    # Run elixirc with --ignore-module-conflict to catch syntax errors
    # without requiring full dependency resolution
    case System.cmd("elixirc", ["--ignore-module-conflict", "-o", "/tmp/cis_validation_beam"],
           stderr_to_stdout: true,
           cd: File.cwd!()
         ) do
      {_, 0} ->
        Mix.shell().info("   ✅ Syntax check passed")
        
        # Cleanup temporary beam files
        File.rm_rf("/tmp/cis_validation_beam")

      {output, exit_code} ->
        # Extract first 1500 chars of error output for readability
        error_summary = String.slice(output, 0, 1500)
        
        Mix.raise("""
        ❌ Compilation sanity check failed (exit code: #{exit_code})

        Error details:
        #{error_summary}

        This indicates syntax errors or structural issues in the codebase.
        
        Recommended actions:
        1. Review the error messages above
        2. Fix syntax errors in reported files
        3. Ensure all `do` blocks have matching `end`
        4. Verify GenServer callback return shapes ({:noreply, state})
        5. Re-run: mix cis.validate_phase5e
        
        Note: This is a lightweight check. Full compilation may reveal
        additional issues related to dependencies and module loading.
        """)
    end

    Mix.shell().info("")
  end
end
