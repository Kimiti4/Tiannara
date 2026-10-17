defmodule TiannaraOS.RecursiveCivilizationRunner do
  @moduledoc """
  RecursiveCivilizationRunner - multi-generation SIMULATION HARNESS for Stage 6.

  This module generates synthetic episodes, simulated theory/validation counts,
  and simulated Stage 3-5 outputs. It does NOT establish real-engine integration,
  real experiments, constitutional compliance, or empirical self-improvement.
  Generated metrics may be random, constant, simplified, or stub-derived.

  ## Evidence Boundary

  This runner is a simulation harness, not a certification runner. By default
  Stage 1-2 outputs and Stage 3-5 results are simulated. Under Phase D staged
  wiring, stages 3, 4, and 5 can execute their genuine engines when requested
  via `stage_modes` (see below); stages 1-2 and metrics remain simulated.
  Do not use harness output as evidence of production behavior or
  empirical self-improvement.

  ## Phase D: machine-readable stage evidence labels (steps 1-4)

  Every run carries a `stage_evidence_labels` map assigning each pipeline
  component an evidence label from the vocabulary `:simulated` or
  `:evidence_backed` (never `:pass` — certification gates stay closed). All
  labels start `:simulated`; a stage flips to `:evidence_backed` only when a
  genuine engine is wired through `opts.stage_modes` (each swap is staged,
  typed, validated, and independently tested).

  Wired so far:
    - **step 2** `stage3_method_evolution`: the runner constructs
      provenance-tagged synthetic `ResearchEpisode` records (metadata
      `harness_synthetic: true`), indexes them into an `EpisodeIndex`, starts
      a real `InstitutionKernel` owning that memory, and executes the genuine
      `MethodEvolutionPipeline.execute_pipeline/3`. Output struct validation
      runs before any result is accepted; engine or validation errors abort
      the run fail-closed (no simulated fallback); the kernel is always
      stopped before the generation ends; per-generation evidence persisted
      to `<output_dir>/stage3_evidence/`. Provenance:
      `genuine_engine_over_harness_synthetic_episodes`.
    - **step 3** `stage4_institution_adaptation`: the runner feeds Stage 3
      `MethodEvolutionResult` structs (with `supporting_episode_ids`
      backfilled from each result's `supporting_episodes` — honest
      derivation) into the genuine `Stage4InstitutionAdaptation.execute_stage_4/3`
      (pure functions, no GenServer). Evidence mode defers every compatible
      proposal with `:awaiting_pilot_evidence` (fail-closed; never fabricates
      adoptions). Per-generation evidence persisted to
      `<output_dir>/stage4_evidence/`. Provenance:
      `genuine_engine_over_stage3_method_evolution_outputs`. Stage 4
      `:evidence_backed` requires stage 3 `:evidence_backed` as well (the
      genuine engine consumes real Stage 3 structs, never fabricated maps).
    - **step 4** `stage5_civilization_adaptation`: the runner feeds Stage 4
      `InstitutionAdaptationResults` (genuine evidence-backed outputs) into
      the genuine `Stage5CivilizationAdaptation.execute_stage_5/3` (pure
      functions, no GenServer). The engine's own validation gates reject
      genuine Stage 4 evidence-backed results (5-stage history, noncompliant
      status), producing the engine's honest blocked result
      (`status: :failed, failure_reason: :no_valid_adaptations`) — the
      runner never fabricates adoption to bypass the gates. Per-generation
      evidence persisted to `<output_dir>/stage5_evidence/`. Provenance:
      `genuine_engine_over_stage4_institution_adaptation_outputs`. Stage 5
      `:evidence_backed` requires stage 4 `:evidence_backed` as well (the
      genuine engine consumes real Stage 4 results, never fabricated maps).

  A companion `stage_provenance` map records, per stage, what each label means
  operationally.

  Labels are persisted machine-readably in:
    - `<output_dir>/stage_evidence_labels.json` (run-level, written at start)
    - each per-generation attestation row (`constitution_attestations.jsonl`)
    - each checkpoint file

  ## Authorization and bounding (Phase D rules)

  `execute/2` requires explicit authorization: `opts.authorized` must be
  `true` or the call raises `ArgumentError` (fail-closed). Runs are bounded:
  `num_generations > 0` and `episodes_per_generation > 0` are enforced.
  Requesting a non-simulated `stage_modes` entry raises until that stage's
  genuine wiring lands — the runner never pretends a stage is wired.

  Every generation executes:
  1. Research Episode Generation (Stage 1-2)
  2. Theory Formation
  3. Distributed Validation
  4. Method Evolution (Stage 3)
  5. Institution Adaptation (Stage 4)
  6. Civilization Adaptation (Stage 5)
  7. Metrics Collection & History Recording

  ## Execution Rule

  Adaptations approved in generation G become active in generation G+1.
  No temporal leakage allowed.

  ## Public API

      RecursiveCivilizationRunner.execute(num_generations, opts)

  Returns in-memory GenerationHistory records from the harness. Persistence and
  immutability must not be inferred from this return value; the CSV writer is stubbed.
  """

  alias TiannaraOS.{
    EpisodeIndex,
    InstitutionKernel,
    MethodEvolutionPipeline,
    MethodEvolutionResult,
    ResearchEpisode,
    ResearchInstitution,
    Stage4InstitutionAdaptation,
    Stage5CivilizationAdaptation
  }


  @doc """
  Execute the civilization for N generations.

  ## Parameters
  - `num_generations`: Number of generations to execute (recommended: 100+)
  - `opts`: Configuration options
    - `authorized`: MUST be `true` — explicit authorization for a bounded run
      (Phase D rule); missing/false raises `ArgumentError`
    - `stage_modes`: Per-stage evidence mode map, e.g.
      `%{stage3_method_evolution: :simulated}`. `:simulated` is supported for
      every stage; `:evidence_backed` is supported only for stages whose
      genuine engine is wired (Phase D steps 2-4: `stage3_method_evolution`,
      `stage4_institution_adaptation`, `stage5_civilization_adaptation`) and
      raises for every other stage. Stage 4 `:evidence_backed` additionally
      requires stage 3 `:evidence_backed`; stage 5 `:evidence_backed`
      additionally requires stage 4 `:evidence_backed`. A `:evidence_backed`
      stage that would not execute (adaptation disabled) also raises — the
      runner never records a label for work that did not run.
    - `output_dir`: Directory for CSV exports (default: "data/stage6")
    - `episodes_per_generation`: Episodes to generate per generation (default: 200, must be > 0)
    - `institutions`: List of institution IDs (default: 20 institutions)
    - `checkpoint_interval`: Save checkpoint every N generations (default: 10)

  ## Returns
  {:ok, [TiannaraOS.Kernel.GenerationHistory.t()]} - List of all generation histories in order

  ## Examples

      {:ok, histories} = RecursiveCivilizationRunner.execute(100, %{
        authorized: true,
        output_dir: "data/stage6",
        episodes_per_generation: 200
      })
  """
  def execute(num_generations, opts \\ %{}) when num_generations > 0 do
    authorized = Map.get(opts, :authorized, false)

    unless authorized == true do
      raise ArgumentError,
        message:
          "RecursiveCivilizationRunner.execute/2 requires explicit authorization " <>
            "(Phase D: bounded, explicitly authorized runs only). " <>
            "Pass opts.authorized: true to proceed."
    end

    output_dir = Map.get(opts, :output_dir, "data/stage6")
    episodes_per_gen = Map.get(opts, :episodes_per_generation, 200)
    institutions = Map.get(opts, :institutions, generate_default_institutions())
    checkpoint_interval = Map.get(opts, :checkpoint_interval, 10)
    enable_adaptation = Map.get(opts, :enable_adaptation, true)  # NEW: Allow disabling adaptation

    unless is_integer(episodes_per_gen) and episodes_per_gen > 0 do
      raise ArgumentError,
        message:
          "episodes_per_generation must be a positive integer (bounded runs), " <>
            "got: #{inspect(episodes_per_gen)}"
    end

    stage_modes = validate_stage_modes(Map.get(opts, :stage_modes, %{}))
    stage_evidence_labels = build_evidence_labels(stage_modes)
    stage_provenance = build_stage_provenance(stage_modes)

    # Phase D: a :evidence_backed label requires the stage to actually execute
    # in this run — never record a label for work that will not run.
    evidence_backed = for {stage, :evidence_backed} <- stage_modes, do: stage

    adaptation_stages = [
      :stage3_method_evolution,
      :stage4_institution_adaptation,
      :stage5_civilization_adaptation
    ]

    if not enable_adaptation and Enum.any?(evidence_backed, &(&1 in adaptation_stages)) do
      raise ArgumentError,
        message:
          "stage_modes requests :evidence_backed for #{inspect(evidence_backed)} but " <>
            "enable_adaptation: false — those stages would not execute. " <>
            "Enable adaptation or use :simulated (Phase D: labels never lie about execution)."
    end

    if :stage3_method_evolution in evidence_backed do
      unless is_list(institutions) and institutions != [] and Enum.all?(institutions, &is_atom/1) do
        raise ArgumentError,
          message:
            "stage_modes.stage3_method_evolution: :evidence_backed requires a non-empty " <>
              "list of atom institution ids (harness kernels register under these names); " <>
              "got: #{inspect(institutions)}"
      end
    end

    # Phase D step 3: stage4's genuine engine consumes Stage 3
    # MethodEvolutionResult structs; requesting :evidence_backed for stage4
    # while stage3 is :simulated would feed fabricated maps to a real engine.
    if :stage4_institution_adaptation in evidence_backed and
         :stage3_method_evolution not in evidence_backed do
      raise ArgumentError,
        message:
          "stage_modes.stage4_institution_adaptation: :evidence_backed requires " <>
            "stage_modes.stage3_method_evolution: :evidence_backed as well — the " <>
            "genuine Stage 4 engine consumes MethodEvolutionResult structs produced " <>
            "by the genuine Stage 3 engine (Phase D: no fabricated inputs to real engines)."
    end

    # Phase D step 4: stage5's genuine engine consumes Stage 4
    # InstitutionAdaptationResults; requesting :evidence_backed for stage5
    # while stage4 is :simulated would feed fabricated maps to a real engine.
    if :stage5_civilization_adaptation in evidence_backed and
         :stage4_institution_adaptation not in evidence_backed do
      raise ArgumentError,
        message:
          "stage_modes.stage5_civilization_adaptation: :evidence_backed requires " <>
            "stage_modes.stage4_institution_adaptation: :evidence_backed as well — the " <>
            "genuine Stage 5 engine consumes InstitutionAdaptationResults produced " <>
            "by the genuine Stage 4 engine (Phase D: no fabricated inputs to real engines)."
    end

    # Ensure output directory exists
    File.mkdir_p!(output_dir)

    # Build constitutional manifest from live system state (canonical Phase 13.5B.3
    # hash ownership) and persist it so manifest_id references remain resolvable.
    manifest = TiannaraOS.Kernel.ConstitutionManifest.build()
    File.write!(
      Path.join(output_dir, "constitution_manifest.json"),
      TiannaraOS.Kernel.ConstitutionManifest.to_json(manifest)
    )

    # Persist run-level machine-readable stage evidence labels (Phase D step 1).
    run_bounds = %{
      generations: num_generations,
      episodes_per_generation: episodes_per_gen,
      checkpoint_interval: checkpoint_interval
    }

    write_run_evidence_labels(output_dir, stage_evidence_labels, stage_modes, stage_provenance, run_bounds)

    IO.puts("=" |> String.duplicate(80))
    IO.puts("Stage 6 - Recursive Civilization SIMULATION HARNESS (NOT CERTIFICATION)")
    IO.puts("Executing #{num_generations} generations...")
    IO.puts("Stage evidence labels: #{inspect(stage_evidence_labels)}")
    IO.puts("=" |> String.duplicate(80))
    IO.puts("")

    # Initialize state
    initial_state = %{
      generation: 0,
      history: [],
      active_adaptations: [],  # Adaptations from previous generation
      total_episodes: 0,
      total_discoveries: 0,
      total_theories: 0,
      research_debt: 0,
      scientific_capital: 0.0,
      budget: 1_000_000,  # Starting budget
      start_time: System.monotonic_time(:millisecond),
      enable_adaptation: enable_adaptation,  # NEW: Track adaptation flag
      # Phase D step 1: machine-readable evidence labeling + authorization
      run_authorized: true,
      stage_modes: stage_modes,
      stage_evidence_labels: stage_evidence_labels,
      stage_provenance: stage_provenance,
      run_bounds: run_bounds
    }

    # Execute generations
    final_state = Enum.reduce(1..num_generations, initial_state, fn gen_num, state ->
      execute_generation(gen_num, state, %{
        episodes_per_generation: episodes_per_gen,
        institutions: institutions,
        output_dir: output_dir,
        checkpoint_interval: checkpoint_interval,
        manifest: manifest,
        stage_provenance: stage_provenance,
        run_bounds: run_bounds
      })
    end)

    # Generate final reports
    generate_final_reports(final_state.history, output_dir)

    IO.puts("")
    IO.puts("=" |> String.duplicate(80))
    IO.puts("Simulation harness finished - #{num_generations} generations processed; real Stage 6 validation NOT ESTABLISHED")
    IO.puts("=" |> String.duplicate(80))

    {:ok, final_state.history}
  end

  # ──────────────────────────────────────────────
  # Phase D: stage evidence labeling
  # ──────────────────────────────────────────────

  @stage_mode_keys [
    :episode_generation,
    :theory_formation,
    :distributed_validation,
    :stage3_method_evolution,
    :stage4_institution_adaptation,
    :stage5_civilization_adaptation,
    :metrics_collection
  ]

  # Wired genuine engines per stage. Phase D step 2 wired stage 3: the genuine
  # MethodEvolutionPipeline executes per institution over provenance-tagged
  # synthetic ResearchEpisode records (inputs are harness-constructed, never
  # field evidence — see stage_provenance). Phase D step 3 wired stage 4: the
  # genuine Stage4InstitutionAdaptation engine consumes Stage 3's
  # MethodEvolutionResult structs (pure functions, no kernel required);
  # evidence-backed mode defers every compatible proposal with
  # :awaiting_pilot_evidence (fail-closed, never fabricates adoptions).
  # Phase D step 4 wired stage 5: the genuine Stage5CivilizationAdaptation
  # engine consumes Stage 4's InstitutionAdaptationResults (pure functions);
  # the engine's validation gates reject evidence-backed Stage 4 results
  # (5-stage history, noncompliant status), producing its honest blocked
  # result — the runner never fabricates adoption to bypass the gates.
  # Requesting :evidence_backed for a stage absent from this set raises
  # (never pretend).
  @wired_evidence_backed_stages MapSet.new([
    :stage3_method_evolution,
    :stage4_institution_adaptation,
    :stage5_civilization_adaptation
  ])

  defp validate_stage_modes(stage_modes) when is_map(stage_modes) do
    Enum.each(stage_modes, fn {stage, mode} ->
      unless stage in @stage_mode_keys do
        raise ArgumentError,
          message:
            "Unknown stage_modes key: #{inspect(stage)}. " <>
              "Valid keys: #{inspect(@stage_mode_keys)}"
      end

      unless mode in [:simulated, :evidence_backed] do
        raise ArgumentError,
          message:
            "Invalid stage mode for #{inspect(stage)}: #{inspect(mode)}. " <>
              "Valid modes: [:simulated, :evidence_backed]"
      end

      if mode == :evidence_backed and not MapSet.member?(@wired_evidence_backed_stages, stage) do
        raise ArgumentError,
          message:
            "Stage #{inspect(stage)} does not support :evidence_backed yet — " <>
              "genuine wiring is not implemented (Phase D staged integration pending). " <>
              "The runner never pretends a stage is wired."
      end
    end)

    # Normalize: every known stage has an explicit mode (default :simulated)
    Map.new(@stage_mode_keys, fn stage ->
      {stage, Map.get(stage_modes, stage, :simulated)}
    end)
  end

  defp validate_stage_modes(stage_modes) do
    raise ArgumentError,
      message: "stage_modes must be a map, got: #{inspect(stage_modes)}"
  end

  defp build_evidence_labels(stage_modes) do
    Map.new(@stage_mode_keys, fn stage -> {stage, Map.fetch!(stage_modes, stage)} end)
  end

  # Operational meaning of each stage's evidence label, machine-readable.
  # :simulated => harness fabricated this stage's output.
  # :evidence_backed for stage3 => the genuine MethodEvolutionPipeline engine
  # executed, but over harness-constructed (synthetic, provenance-tagged)
  # ResearchEpisode inputs — never observed field evidence.
  # :evidence_backed for stage4 => the genuine Stage4InstitutionAdaptation
  # engine executed over Stage 3 MethodEvolutionResult structs; evidence mode
  # defers every compatible proposal (no fabricated adoptions).
  # :evidence_backed for stage5 => the genuine Stage5CivilizationAdaptation
  # engine executed over Stage 4 InstitutionAdaptationResults; the engine's
  # validation gates reject evidence-backed Stage 4 results, producing its
  # honest blocked result (no fabricated adoption).
  defp build_stage_provenance(stage_modes) do
    Map.new(@stage_mode_keys, fn stage ->
      provenance =
        case {stage, Map.fetch!(stage_modes, stage)} do
          {:stage3_method_evolution, :evidence_backed} ->
            "genuine_engine_over_harness_synthetic_episodes"

          {:stage4_institution_adaptation, :evidence_backed} ->
            "genuine_engine_over_stage3_method_evolution_outputs"

          {:stage5_civilization_adaptation, :evidence_backed} ->
            "genuine_engine_over_stage4_institution_adaptation_outputs"

          {_stage, :evidence_backed} ->
            "genuine_engine"

          {_stage, :simulated} ->
            "harness_fabricated_output"
        end

      {stage, provenance}
    end)
  end

  defp write_run_evidence_labels(output_dir, labels, stage_modes, stage_provenance, bounds) do
    payload = %{
      run_authorized: true,
      bounded: bounds,
      stage_evidence_labels: labels,
      stage_modes: stage_modes,
      stage_provenance: stage_provenance,
      certification_claim: "none",
      note:
        "Evidence labels are machine-readable runner state. :simulated means the " <>
          "harness fabricated this stage's output; :evidence_backed requires a wired " <>
          "genuine engine (see stage_provenance for what that engine actually ran " <>
          "over). This vocabulary never contains :pass — certification gates " <>
          "remain closed."
    }

    File.write!(
      Path.join(output_dir, "stage_evidence_labels.json"),
      Jason.encode!(payload, pretty: true)
    )
  end

  # ──────────────────────────────────────────────
  # Single Generation Execution
  # ──────────────────────────────────────────────

  defp execute_generation(gen_num, state, config) do
    IO.puts("\n" <> ("─" |> String.duplicate(80)))
    IO.puts("Generation #{gen_num}")
    IO.puts("─" |> String.duplicate(80))

    gen_start_time = System.monotonic_time(:millisecond)

    # Apply adaptations from previous generation (if any)
    adapted_state = apply_pending_adaptations(state)

    # Execute Stage 1-2: Research Episode Generation
    IO.puts("\n📊 SIMULATING Stages 1-2: Research Episode Generation...")
    episodes = simulate_episode_generation(config.episodes_per_generation, gen_num)
    IO.puts("  ✓ Generated #{length(episodes)} episodes")

    # Execute Theory Formation (simulated)
    IO.puts("\n🧠 SIMULATING Theory Formation...")
    theories_formed = simulate_theory_formation(episodes, gen_num)
    IO.puts("  ✓ Formed #{theories_formed} theories")

    # Execute Distributed Validation (simulated)
    IO.puts("\n✅ SIMULATING Distributed Validation...")
    unknowns_resolved = simulate_validation(episodes, gen_num)
    IO.puts("  ✓ Resolved #{unknowns_resolved} unknowns")

    # Execute Stages 3-5 only if adaptation is enabled
    {stage3_results, stage4_results, stage5_result} = if adapted_state.enable_adaptation do
      # Execute Stage 3: Method Evolution (mode from stage_modes; Phase D step 2
      # wires :evidence_backed to the genuine MethodEvolutionPipeline)
      stage3_mode = adapted_state.stage_modes.stage3_method_evolution

      stage3 = case stage3_mode do
        :evidence_backed ->
          IO.puts("\n🔬 EXECUTING Stage 3: Method Evolution (genuine MethodEvolutionPipeline, " <>
                    "inputs are harness-constructed synthetic episodes)...")
          execute_stage3_evidence_backed(episodes, gen_num, config)

        :simulated ->
          IO.puts("\n📊 SIMULATING Stage 3: Method Evolution (real engine not called)...")
          execute_stage3(episodes, gen_num)
      end

      IO.puts("  ✓ Produced #{length(stage3)} MethodEvolutionResults")

      # Execute Stage 4: Institution Adaptation (mode from stage_modes; Phase D
      # step 3 wires :evidence_backed to the genuine Stage4InstitutionAdaptation
      # engine — pure functions over Stage 3 MethodEvolutionResult structs)
      stage4_mode = adapted_state.stage_modes.stage4_institution_adaptation

      stage4 = case stage4_mode do
        :evidence_backed ->
          IO.puts("\n🏛️  EXECUTING Stage 4: Institution Adaptation (genuine " <>
                    "Stage4InstitutionAdaptation over Stage 3 results)...")
          execute_stage4_evidence_backed(stage3, gen_num, config)

        :simulated ->
          IO.puts("\n🏛️  SIMULATING Stage 4: Institution Adaptation (real engine not called)...")
          execute_stage4(stage3, config.institutions, gen_num)
      end

      IO.puts("  ✓ Produced #{length(stage4)} InstitutionAdaptationResults")

      # Execute Stage 5: Civilization Adaptation (mode from stage_modes; Phase D
      # step 4 wires :evidence_backed to the genuine Stage5CivilizationAdaptation
      # engine — consumes Stage 4 InstitutionAdaptationResults)
      stage5_mode = adapted_state.stage_modes.stage5_civilization_adaptation

      stage5 = case stage5_mode do
        :evidence_backed ->
          IO.puts("\n🌍 EXECUTING Stage 5: Civilization Adaptation (genuine " <>
                    "Stage5CivilizationAdaptation over Stage 4 results)...")
          execute_stage5_evidence_backed(stage4, gen_num, config)

        :simulated ->
          IO.puts("\n🌍 SIMULATING Stage 5: Civilization Adaptation (based on simulated inputs)...")
          execute_stage5(stage4, gen_num)
      end
      IO.puts("  ✓ Civilization decision: #{inspect(stage5.civilization_decision)}")

      {stage3, stage4, stage5}
    else
      # Static civilization - skip adaptation stages
      IO.puts("\n⏸️  Adaptation disabled (static civilization)")
      {[], [], %{id: "static_gen#{gen_num}", civilization_decision: :no_adaptation, supporting_institutions: []}}
    end

    # Collect metrics
    IO.puts("\n📈 Collecting harness metrics (some synthetic, constant, or stub-derived)...")
    history = collect_generation_metrics(%{
      generation_number: gen_num,
      start_time: gen_start_time,
      episodes: episodes,
      theories_formed: theories_formed,
      unknowns_resolved: unknowns_resolved,
      stage3_results: stage3_results,
      stage4_results: stage4_results,
      stage5_result: stage5_result,
      state: adapted_state,
      manifest: config.manifest,
      output_dir: config.output_dir
    })

    # Append to history (immutable)
    updated_history = state.history ++ [history]

    # Save to CSV
    csv_path = Path.join(config.output_dir, "generation_history.csv")
    TiannaraOS.Kernel.GenerationHistory.append_to_file(history, csv_path)

    # Update state with new totals
    updated_state = %{
      adapted_state |
      generation: gen_num,
      history: updated_history,
      total_episodes: adapted_state.total_episodes + length(episodes),
      total_discoveries: adapted_state.total_discoveries + history.discoveries_made,
      total_theories: adapted_state.total_theories + theories_formed,
      research_debt: max(0, adapted_state.research_debt + history.research_debt - unknowns_resolved),
      scientific_capital: history.scientific_capital,  # Already cumulative from collect_generation_metrics
      budget: adapted_state.budget - history.credits_spent,
      active_adaptations: extract_approved_adaptations(stage5_result)
    }

    # Checkpoint
    if rem(gen_num, config.checkpoint_interval) == 0 do
      IO.puts("\n💾 Checkpoint at generation #{gen_num}")
      save_checkpoint(updated_state, config.output_dir, gen_num)
    end

    # Display summary
    display_generation_summary(history, gen_num)

    updated_state
  end

  # ──────────────────────────────────────────────
  # Stage Execution Helpers
  # ──────────────────────────────────────────────

  defp execute_stage3(_episodes, gen_num) do
    # SIMULATION ONLY: do not treat these randomized placeholders as engine output.
    # The real Stage3MethodEvolution engine is not invoked by this harness.
    Enum.map(1..Enum.random(3..8), fn i ->
      %{
        id: "method_evol_#{gen_num}_#{i}",
        generation: gen_num,
        methods_evaluated: Enum.random(10..50),
        improvements_identified: Enum.random(1..5),
        prediction_accuracy: %{
          average_absolute_error: :rand.uniform() * 0.02 + 0.01,
          prediction_reliability_rate: 0.7 + (:rand.uniform() * 0.2)
        }
      }
    end)
  end

  # ──────────────────────────────────────────────
  # Phase D step 2: genuine Stage 3 wiring
  #
  # Executes the genuine MethodEvolutionPipeline per institution. Inputs are
  # harness-constructed ResearchEpisode records derived from the generation's
  # synthetic episodes, tagged metadata.harness_synthetic = true, finalized
  # and indexed so the engine's own retrieval path resolves them. Engine
  # errors and output-validation failures abort the run fail-closed. Each
  # generation persists machine-readable evidence to
  # <output_dir>/stage3_evidence/generation_<n>.json. Institution kernels are
  # stopped after each stage run (no process leaks across generations).
  # ──────────────────────────────────────────────

  defp execute_stage3_evidence_backed(episodes, gen_num, config) do
    results =
      Enum.map(config.institutions, fn institution_id ->
        run_stage3_for_institution(institution_id, episodes, gen_num, config)
      end)

    persist_stage3_evidence(gen_num, results, config)
    results
  end

  defp run_stage3_for_institution(institution_id, episodes, gen_num, _config) do
    # Harness-only kernel namespace: never collide with a real institution.
    harness_id = :"stage6_harness_#{institution_id}"

    research_episodes =
      Enum.map(episodes, fn ep ->
        build_research_episode(ep, harness_id, gen_num)
      end)

    index =
      Enum.reduce(research_episodes, EpisodeIndex.new(harness_id), fn episode, acc ->
        EpisodeIndex.add_entry(acc, episode)
      end)

    memory = %{
      episode_index: index,
      episodes: Map.new(research_episodes, &{&1.episode_id, &1}),
      stored_episodes: Enum.map(research_episodes, & &1.episode_id)
    }

    institution =
      ResearchInstitution.new(harness_id, :stage6_harness_world, gen_num)
      |> Map.put(:civilizational_memory, memory)

    case InstitutionKernel.start_link(harness_id, institution) do
      {:ok, kernel_pid} ->
        try do
          seed = MethodEvolutionResult.new(harness_id)

          case MethodEvolutionPipeline.execute_pipeline(seed, harness_id, %{}) do
            {:ok, result} ->
              validate_stage3_output!(result, harness_id, length(research_episodes))

              # Tag the genuine struct with the original institution_id (the
              # engine ran under harness_id) so downstream harness consumers
              # and Stage 4 see a consistent institution mapping.
              %{result | institution_id: institution_id}

            {:error, reason} ->
              raise ArgumentError,
                message:
                  "Genuine Stage 3 engine returned error for #{inspect(harness_id)} " <>
                    "at generation #{gen_num} (fail-closed, no simulated fallback): " <>
                    inspect(reason)
          end
        after
          stop_institution_kernel(kernel_pid)
        end

      {:error, {:already_started, _pid}} ->
        raise ArgumentError,
          message:
            "Institution kernel #{inspect(harness_id)} is already running — refusing to " <>
              "reuse or stop a kernel this run did not start (Phase D fail-closed)."

      {:error, reason} ->
        raise ArgumentError,
          message:
            "Failed to start harness institution kernel #{inspect(harness_id)} at " <>
              "generation #{gen_num}: #{inspect(reason)}"
    end
  end

  defp stop_institution_kernel(pid) do
    if Process.alive?(pid) do
      try do
        GenServer.stop(pid, :normal, 5_000)
      catch
        :exit, _ -> Process.exit(pid, :kill)
      end
    end
  end

  # Derive a genuine, finalized ResearchEpisode from a synthetic episode map.
  # Costs and value are deterministic derivations of the synthetic
  # characteristics (not engine outputs) so the pipeline's resource metrics
  # have real arithmetic to operate on.
  defp build_research_episode(syn, harness_id, gen_num) do
    cost = syn.complexity * 1.0
    value = (1.0 - syn.difficulty) * syn.complexity

    base =
      ResearchEpisode.new(harness_id, "harness investigation #{syn.id}", %{
        tick: gen_num,
        domain: syn.domain,
        description:
          "Harness-constructed synthetic investigation (complexity=#{syn.complexity}, " <>
            "uncertainty=#{syn.uncertainty}, difficulty=#{syn.difficulty})",
        keywords: [Atom.to_string(syn.domain), "harness_synthetic"],
        metadata: %{
          harness_synthetic: true,
          synthetic_episode_id: syn.id,
          generation: gen_num,
          complexity: syn.complexity,
          uncertainty: syn.uncertainty,
          difficulty: syn.difficulty
        }
      })

    with_validation =
      if syn.difficulty < 0.5 do
        ResearchEpisode.add_validation(base, "harness_validation_#{syn.id}")
      else
        base
      end

    with_contributor =
      if syn.difficulty < 0.6 do
        ResearchEpisode.add_contributor(with_validation, :harness_collaborator)
      else
        with_validation
      end

    with_contributor
    |> ResearchEpisode.add_cost(cost, :research)
    |> ResearchEpisode.update_value_generated(Float.round(value, 4))
    |> ResearchEpisode.finalize(gen_num)
  end

  defp validate_stage3_output!(%MethodEvolutionResult{} = result, harness_id, expected_episodes) do
    cond do
      result.episodes_analyzed != expected_episodes ->
        raise ArgumentError,
          message:
            "Stage 3 output validation failed for #{inspect(harness_id)}: " <>
              "episodes_analyzed=#{result.episodes_analyzed}, expected #{expected_episodes}"

      result.supporting_episodes in [nil, []] ->
        raise ArgumentError,
          message:
            "Stage 3 output validation failed for #{inspect(harness_id)}: " <>
              "supporting_episodes is empty — engine result lacks evidence linkage"

      not is_map(result.evidence_summary) ->
        raise ArgumentError,
          message:
            "Stage 3 output validation failed for #{inspect(harness_id)}: " <>
              "evidence_summary missing"

      true ->
        :ok
    end

    result
  end

  defp validate_stage3_output!(other, harness_id, _expected) do
    raise ArgumentError,
      message:
        "Stage 3 output validation failed for #{inspect(harness_id)}: " <>
          "engine returned #{inspect(other)}, expected %MethodEvolutionResult{}"
  end

  defp persist_stage3_evidence(gen_num, results, config) do
    evidence_dir = Path.join(config.output_dir, "stage3_evidence")
    File.mkdir_p!(evidence_dir)

    institution_rows =
      Enum.map(results, fn %MethodEvolutionResult{} = r ->
        %{
          institution_id: r.institution_id,
          result_id: r.id,
          episodes_analyzed: r.episodes_analyzed,
          candidate_improvements: length(r.candidate_improvements || []),
          supporting_episodes: length(r.supporting_episodes || []),
          insufficient_data_metrics: (r.evidence_summary || %{})[:insufficient_data_metrics] || [],
          exclusions: (r.evidence_summary || %{})[:exclusions] || []
        }
      end)

    payload = %{
      generation: gen_num,
      stage: "stage3_method_evolution",
      stage_mode: "evidence_backed",
      stage_provenance: Map.get(config.stage_provenance || %{}, :stage3_method_evolution),
      engine: "TiannaraOS.MethodEvolutionPipeline.execute_pipeline/3",
      input_provenance:
        "harness_synthetic_research_episodes (metadata.harness_synthetic=true; not field evidence)",
      institutions: institution_rows,
      certification_claim: "none"
    }

    File.write!(
      Path.join(evidence_dir, "generation_#{gen_num}.json"),
      Jason.encode!(payload, pretty: true)
    )
  end

  # ──────────────────────────────────────────────
  # Phase D step 3: genuine Stage 4 wiring
  #
  # Executes the genuine Stage4InstitutionAdaptation engine over Stage 3
  # MethodEvolutionResult structs (pure functions, no GenServer). Inputs are
  # the genuine Stage 3 outputs; proposals are backfilled with
  # supporting_episode_ids from each result's supporting_episodes (honest
  # derivation — the engine requires them for evidence-backed validation).
  # Evidence mode defers every compatible proposal with
  # :awaiting_pilot_evidence (fail-closed; never fabricates adoptions).
  # Results are converted to plain maps for downstream harness compatibility
  # while preserving the genuine engine's vocabulary (:adopted/:none_adopted,
  # not the harness's :adopt). Per-generation evidence persisted to
  # <output_dir>/stage4_evidence/generation_<n>.json.
  # ──────────────────────────────────────────────

  defp execute_stage4_evidence_backed(stage3_results, gen_num, config) do
    mers = Enum.map(stage3_results, &backfill_supporting_episode_ids/1)

    out =
      Stage4InstitutionAdaptation.execute_stage_4(mers, :all, %{
        evidence_mode: :evidence_backed,
        budget: 10_000,
        pilot_programs: 1,
        simulation_generations: 3
      })

    adaptation_results =
      Map.get(out, :adaptation_results, [])
      |> Enum.map(&Map.from_struct/1)

    persist_stage4_evidence(gen_num, out, adaptation_results, config)
    adaptation_results
  end

  # Genuine Stage 3 proposals carry supporting_episode_count but not
  # supporting_episode_ids (the pipeline omits them). Backfill from the
  # result's supporting_episodes — honest derivation from the same genuine
  # run's evidence linkage, never invented.
  defp backfill_supporting_episode_ids(%MethodEvolutionResult{} = mer) do
    ids = mer.supporting_episodes || []

    proposals =
      Enum.map(mer.candidate_improvements || [], fn proposal ->
        Map.put_new(proposal, :supporting_episode_ids, ids)
      end)

    %{mer | candidate_improvements: proposals}
  end

  defp backfill_supporting_episode_ids(other), do: other

  defp persist_stage4_evidence(gen_num, out, adaptation_results, config) do
    evidence_dir = Path.join(config.output_dir, "stage4_evidence")
    File.mkdir_p!(evidence_dir)

    deferral_reasons =
      Enum.flat_map(adaptation_results, fn r ->
        (r.simulation_results || %{})
        |> Map.get(:deferred_proposals, [])
        |> Enum.map(&Map.get(&1, :deferral_reason))
      end)

    payload = %{
      generation: gen_num,
      stage: "stage4_institution_adaptation",
      stage_mode: "evidence_backed",
      stage_provenance: Map.get(config.stage_provenance || %{}, :stage4_institution_adaptation),
      engine: "TiannaraOS.Stage4InstitutionAdaptation.execute_stage_4/3",
      input_provenance: "genuine_stage3_method_evolution_outputs (MethodEvolutionResult structs)",
      evidence_mode: Map.get(out, :evidence_mode),
      total_adopted: Map.get(out, :total_adopted, 0),
      total_rejected: Map.get(out, :total_rejected, 0),
      total_deferred: Map.get(out, :total_deferred, 0),
      adaptation_results_count: length(adaptation_results),
      deferral_reasons: deferral_reasons,
      note:
        "Genuine engine executed in :evidence_backed mode — every compatible " <>
          "proposal is deferred with :awaiting_pilot_evidence; no adoptions " <>
          "are fabricated. Adoption requires pilot evidence this harness does " <>
          "not produce.",
      certification_claim: "none"
    }

    File.write!(
      Path.join(evidence_dir, "generation_#{gen_num}.json"),
      Jason.encode!(payload, pretty: true)
    )
  end

  defp execute_stage4(_stage3_results, institutions, gen_num) do
    # Simulate Stage 4 execution for each institution
    Enum.map(institutions, fn inst_id ->
      success_rate = 0.3 + (gen_num * 0.02) + (:rand.uniform() * 0.2)
      success_rate = min(success_rate, 0.9)

      improvement = if success_rate > 0.6 do
        :rand.uniform() * 0.12
      else
        :rand.uniform() * 0.03
      end

      predicted_improvement = improvement + (:rand.uniform() - 0.5) * 0.03

      %{
        id: "inst_adapt_#{inst_id}_gen#{gen_num}",
        institution_id: inst_id,
        generation: gen_num,
        adoption_decision: if(success_rate > 0.7, do: :adopt, else: :reject),
        pilot_results: %{
          success_rate: Float.round(success_rate, 4),
          actual_improvement: Float.round(improvement, 4)
        },
        simulation_results: %{
          predicted_improvement: Float.round(predicted_improvement, 4),
          prediction_accuracy: %{
            absolute_error: abs(predicted_improvement - improvement),
            prediction_reliable: abs(predicted_improvement - improvement) < 0.05
          }
        },
        stage_history: generate_lifecycle_stages(inst_id),
        constitutional_compliance: true
      }
    end)
  end

  # ──────────────────────────────────────────────
  # Phase D step 4: genuine Stage 5 wiring
  #
  # Executes the genuine Stage5CivilizationAdaptation engine over Stage 4
  # InstitutionAdaptationResults (pure functions, no GenServer). Inputs are
  # the genuine Stage 4 evidence-backed outputs (deferred/noncompliant
  # results, never fabricated adoptions). The engine's validate_adaptations/1
  # enforces four gates — stage_history >= 7, constitutional compliance,
  # rollback availability, and explicit evidence-source labeling — which
  # genuine Stage 4 evidence-backed results do not satisfy (5-stage history,
  # noncompliant status). The engine therefore returns its honest blocked
  # result (status: :failed, failure_reason: :no_valid_adaptations); the
  # runner never fabricates adoption to bypass those gates. Per-generation
  # evidence persisted to <output_dir>/stage5_evidence/.
  # ──────────────────────────────────────────────

  defp execute_stage5_evidence_backed(stage4_results, gen_num, config) do
    result =
      Stage5CivilizationAdaptation.execute_stage_5(stage4_results, :tiannara,
        generation: gen_num,
        min_institutions: 15,
        prediction_reliability_threshold: 0.6
      )

    persist_stage5_evidence(gen_num, result, config)
    result
  end

  defp persist_stage5_evidence(gen_num, result, config) do
    evidence_dir = Path.join(config.output_dir, "stage5_evidence")
    File.mkdir_p!(evidence_dir)

    payload = %{
      generation: gen_num,
      stage: "stage5_civilization_adaptation",
      stage_mode: "evidence_backed",
      stage_provenance: Map.get(config.stage_provenance || %{}, :stage5_civilization_adaptation),
      engine: "TiannaraOS.Stage5CivilizationAdaptation.execute_stage_5/3",
      input_provenance: "genuine_stage4_institution_adaptation_outputs (InstitutionAdaptationResults)",
      result_id: result.id,
      civilization_decision: result.civilization_decision,
      status: result.status,
      failure_reason: result.failure_reason,
      institutions_evaluated: result.institutions_evaluated,
      supporting_institutions_count: length(result.supporting_institutions || []),
      note:
        "Genuine engine executed over genuine Stage 4 evidence-backed outputs. " <>
          "Stage 4 evidence mode defers every proposal (:awaiting_pilot_evidence) " <>
          "and produces noncompliant results, so the engine's validation gates " <>
          "(stage_history >= 7, compliance, rollback, evidence-source) reject " <>
          "them and the result is the engine's honest blocked outcome — " <>
          "status: :failed, failure_reason: :no_valid_adaptations. Adoption is " <>
          "never fabricated by the runner.",
      certification_claim: "none"
    }

    File.write!(
      Path.join(evidence_dir, "generation_#{gen_num}.json"),
      Jason.encode!(payload, pretty: true)
    )
  end

  defp execute_stage5(stage4_results, gen_num) do
    # Simulate Stage 5 execution
    adopted_count = Enum.count(stage4_results, fn r -> r.adoption_decision == :adopt end)
    total_count = length(stage4_results)

    decision = cond do
      adopted_count >= total_count * 0.5 -> :universal_adoption
      adopted_count >= total_count * 0.2 -> :selective_adoption
      adopted_count > 0 -> :experimental_expansion
      true -> :preserve_diversity
    end

    %{
      id: "civ_adapt_gen#{gen_num}",
      generation: gen_num,
      civilization_decision: decision,
      supporting_institutions: Enum.take(Enum.shuffle(stage4_results), min(adopted_count, 10)),
      adaptation_families: Enum.random(2..8),
      transferability_analysis: %{
        universal_count: if(decision == :universal_adoption, do: Enum.random(1..3), else: 0),
        domain_specific_count: if(decision == :selective_adoption, do: Enum.random(2..5), else: 0),
        experimental_count: if(decision == :experimental_expansion, do: Enum.random(1..4), else: 0)
      }
    }
  end

  # ──────────────────────────────────────────────
  # Metrics Collection
  # ──────────────────────────────────────────────

  defp collect_generation_metrics(data) do
    gen_num = data.generation_number
    stage4_results = data.stage4_results
    stage5_result = data.stage5_result

    # Calculate metrics
    adaptations_evaluated = length(stage4_results)
    adaptations_adopted = Enum.count(stage4_results, fn r -> r.adoption_decision == :adopt end)
    adaptations_rejected = adaptations_evaluated - adaptations_adopted
    adaptation_success_rate = if adaptations_evaluated > 0 do
      Float.round(adaptations_adopted / adaptations_evaluated, 3)
    else
      0.0
    end

    # Prediction accuracy aggregation
    prediction_accuracies = Enum.map(stage4_results, fn r ->
      case get_in(r, [:simulation_results, :prediction_accuracy]) do
        %{absolute_error: err} -> err
        _ -> nil
      end
    end)
    |> Enum.filter(& &1)

    avg_prediction_error = if length(prediction_accuracies) > 0 do
      Float.round(Enum.sum(prediction_accuracies) / length(prediction_accuracies), 4)
    else
      nil
    end

    prediction_reliability = if length(prediction_accuracies) > 0 do
      reliable_count = Enum.count(prediction_accuracies, fn e -> e < 0.05 end)
      Float.round(reliable_count / length(prediction_accuracies), 3)
    else
      nil
    end

    # Research velocity (discoveries per unit time)
    research_velocity = Float.round(data.theories_formed / 1.0, 2)  # Simplified

    # Scientific Capital - CONSTITUTIONAL CONSERVED QUANTITY
    # Derived exclusively from validated canonical transactions using ScientificCapitalPolicy
    # NO stochastic variation, NO adaptation bonuses, NO heuristics
    # Randomness belongs in episode production, NOT in capital calculation
    
    # Get current constitutional policy (versioned, reviewable, experimentally validated)
    policy = TiannaraOS.ScientificCapitalPolicy.current()
    
    # Per-generation capital increase (ΔCapital) calculated using policy coefficients
    # Note: In current simulation, discoveries_made = theories_formed
    transactions = %{
      discoveries_made: data.theories_formed,  # discoveries = theories in current sim
      theories_formed: data.theories_formed,
      unknowns_resolved: data.unknowns_resolved
    }
    delta_capital = TiannaraOS.Kernel.ScientificCapitalLedger.calculate_delta(policy, transactions)
    
    # Cumulative scientific capital (monotonically increasing)
    # This represents total accumulated validated knowledge stock
    previous_capital = Map.get(data, :state, %{}) |> Map.get(:scientific_capital, 0)
    _scientific_capital = previous_capital + delta_capital

    # Diversity metrics - seed-driven variation
    institution_diversity = calculate_institution_diversity(stage4_results)
    method_diversity = 0.6 + (:rand.uniform() * 0.3)  # Varies 0.6-0.9 based on seed
    collaboration_density = 0.2 + (:rand.uniform() * 0.3) + (gen_num * 0.003)  # Base variation + improvement

    # Calculate CAI
    cai_sample = %{
      adaptation_success_rate: adaptation_success_rate,
      prediction_reliability: prediction_reliability || 0.5,
      rollback_frequency: 0.05,  # Low rollback frequency
      constitutional_violations: 0,
      institution_diversity: institution_diversity,
      method_diversity: method_diversity
    }
    civilization_adaptation_index = TiannaraOS.Kernel.GenerationHistory.calculate_cai(cai_sample)

    # Resource utilization - seed-driven variation
    credits_spent = adaptations_evaluated * 100 + adaptations_adopted * 500
    # Add variation based on episode complexity (seed-dependent)
    avg_episode_complexity = if length(data.episodes) > 0 do
      Enum.sum(Enum.map(data.episodes, fn e -> Map.get(e, :complexity, 20) end)) / length(data.episodes)
    else
      20
    end
    complexity_multiplier = avg_episode_complexity / 20.0
    credits_spent = round(credits_spent * complexity_multiplier * (0.95 + :rand.uniform() * 0.1))
    
    budget_remaining = max(0, data.state.budget - credits_spent)

    # Constitutional provenance (Phase 13.5B.3): the run-start manifest owns all
    # component hashes (policy, definition, ledger, invariant registry, combined).
    # A per-generation certificate binds this history row to that manifest with
    # honest statuses - this harness performs no real validation, replay,
    # watchdog, or invariant verification, so those are recorded as
    # :not_verified/:not_run and the certification level resolves to "minimal".
    certificate =
      TiannaraOS.Kernel.ConstitutionCertificate.generate(
        execution_id: "harness_gen_#{gen_num}_#{:erlang.unique_integer([:positive])}",
        generation_count: gen_num,
        manifest: data.manifest,
        validation_status: :harness_simulated,
        replay_status: :not_verified,
        watchdog_status: :not_run,
        invariant_status: :not_verified
      )

    persist_attestation(data, gen_num, certificate)

    # Build history record
    TiannaraOS.Kernel.GenerationHistory.new(%{
      generation_number: gen_num,
      execution_duration_ms: System.monotonic_time(:millisecond) - data.start_time,
      episodes_created: length(data.episodes),
      discoveries_made: data.theories_formed,
      theories_formed: data.theories_formed,
      unknowns_resolved: data.unknowns_resolved,
      research_debt: max(0, data.state.research_debt - data.unknowns_resolved + Enum.random(0..5)),
      research_velocity: research_velocity,
      replication_success_rate: 0.8 + (:rand.uniform() * 0.15),
      adaptations_evaluated: adaptations_evaluated,
      adaptations_adopted: adaptations_adopted,
      adaptations_rejected: adaptations_rejected,
      adaptation_success_rate: adaptation_success_rate,
      prediction_accuracy: %{average_absolute_error: avg_prediction_error},
      prediction_calibration: avg_prediction_error && Float.round(1.0 - avg_prediction_error, 3),
      prediction_reliability: prediction_reliability,
      civilization_adaptation_index: civilization_adaptation_index,
      scientific_capital: delta_capital,  # Store per-generation delta for conservation audit
      institution_diversity: institution_diversity,
      method_diversity: method_diversity,
      collaboration_density: Float.round(collaboration_density, 3),
      resource_utilization: %{cpu_percent: 45.0, memory_mb: 512},
      budget_remaining: budget_remaining,
      credits_spent: credits_spent,
      canonical_transaction_ids: [
        "stage3_#{gen_num}",
        "stage4_#{gen_num}",
        stage5_result.id
      ],
      stage3_results_count: length(data.stage3_results),
      stage4_results_count: length(stage4_results),
      stage5_result_id: stage5_result.id,
      constitutional_violations: 0,
      lifecycle_completeness_pct: 100.0,
      rollback_frequency: 0.05,
      # Constitutional provenance linkage (Phase 13.5B.3) - hashes live in the
      # persisted manifest referenced by manifest_id
      manifest_id: data.manifest.manifest_id,
      certificate_id: certificate.certificate_id
    })
  end

  # Persist per-generation constitutional attestation (append-only JSONL) so
  # manifest_id/certificate_id on history rows remain resolvable against the
  # certificate hash and constitution combined hash. Phase D step 1: each row
  # also carries the machine-readable stage evidence labels and the run's
  # explicit authorization record.
  defp persist_attestation(data, gen_num, certificate) do
    attestation = %{
      generation_number: gen_num,
      manifest_id: certificate.manifest.manifest_id,
      certificate_id: certificate.certificate_id,
      certificate_hash: certificate.certificate_hash,
      constitution_combined_hash: certificate.combined_hash,
      certification_level: certificate.metadata.certification_level,
      # Phase D: machine-readable evidence labeling + authorization record
      stage_evidence_labels: data.state.stage_evidence_labels,
      stage_provenance: Map.get(data.state, :stage_provenance, %{}),
      run_authorized: data.state.run_authorized,
      bounded: data.state.run_bounds
    }

    File.write!(
      Path.join(data.output_dir, "constitution_attestations.jsonl"),
      Jason.encode!(attestation) <> "\n",
      [:append]
    )
  end

  # ──────────────────────────────────────────────
  # Simulation Helpers
  # ──────────────────────────────────────────────

  defp simulate_episode_generation(count, gen_num) do
    # Generate episodes with seed-driven variation
    # Each seed produces different episode characteristics
    base_complexity = 10 + :rand.uniform(21)  # Range: 10 to 30
    base_uncertainty = 5 + :rand.uniform(16)  # Range: 5 to 20
    
    Enum.map(1..count, fn i ->
      # Vary episode properties based on RNG state (seed-dependent)
      complexity = base_complexity + (:rand.uniform(11) - 5)  # Range: -5 to +5
      uncertainty = base_uncertainty + (:rand.uniform(7) - 3)  # Range: -3 to +3
      domain = Enum.random([:physics, :biology, :chemistry, :computation])
      
      %{
        id: "episode_#{gen_num}_#{i}",
        complexity: max(1, complexity),
        uncertainty: max(0, uncertainty),
        domain: domain,
        difficulty: Float.round(:rand.uniform() * 0.5 + 0.3, 2)
      }
    end)
  end

  defp simulate_theory_formation(episodes, _gen_num) do
    # Theory formation rate varies SIGNIFICANTLY based on episode characteristics AND seed
    avg_difficulty = Enum.sum(Enum.map(episodes, & &1.difficulty)) / length(episodes)
    
    # Base rate now strongly depends on difficulty (0.02 to 0.08 range)
    base_rate = 0.02 + (avg_difficulty * 0.12)
    
    # Very strong seed-driven variation (±50%)
    seed_variation = 0.5 + (:rand.uniform() * 1.0)  # Range: 0.5 to 1.5
    
    round(length(episodes) * base_rate * seed_variation)
  end

  defp simulate_validation(episodes, _gen_num) do
    # Validation success varies SIGNIFICANTLY based on episode uncertainty AND seed
    avg_uncertainty = Enum.sum(Enum.map(episodes, & &1.uncertainty)) / length(episodes)
    
    # Base rate now strongly depends on uncertainty (0.01 to 0.05 range)
    base_rate = 0.01 + (avg_uncertainty * 0.002)
    
    # Very strong seed-driven variation (±60%)
    seed_variation = 0.4 + (:rand.uniform() * 1.2)  # Range: 0.4 to 1.6
    
    round(length(episodes) * base_rate * seed_variation)
  end

  defp apply_pending_adaptations(state) do
    # Apply adaptations approved in previous generation
    # For now, just track them (actual application would modify behavior)
    state
  end

  defp extract_approved_adaptations(stage5_result) do
    # Extract adaptations approved by civilization
    stage5_result.supporting_institutions || []
  end

  defp calculate_institution_diversity(stage4_results) do
    # Measure diversity of institutional specializations
    if length(stage4_results) > 0 do
      unique_institutions = stage4_results
        |> Enum.map(fn r -> r.institution_id end)
        |> Enum.uniq()
        |> length()

      Float.round(unique_institutions / length(stage4_results), 3)
    else
      0.0
    end
  end

  defp generate_lifecycle_stages(inst_id) do
    stages = [
      :proposal_received, :compatibility_analyzed, :risk_assessed,
      :simulated, :piloted, :performance_compared, :governance_reviewed,
      :decision_recorded, :rollback_generated,
      :constitutional_validation_completed, :adaptation_closed
    ]

    Enum.map(stages, fn stage ->
      %{stage: stage, timestamp: DateTime.utc_now(), metadata: %{institution: inst_id}}
    end)
  end

  defp generate_default_institutions do
    [
      :institution_alpha, :institution_beta, :institution_gamma,
      :institution_delta, :institution_epsilon, :institution_zeta,
      :institution_eta, :institution_theta, :institution_iota,
      :institution_kappa, :institution_lambda, :institution_mu,
      :institution_nu, :institution_xi, :institution_omicron,
      :institution_pi, :institution_rho, :institution_sigma,
      :institution_tau, :institution_upsilon
    ]
  end

  # ──────────────────────────────────────────────
  # Reporting & Checkpoints
  # ──────────────────────────────────────────────

  defp display_generation_summary(history, gen_num) do
    IO.puts("\n📊 Generation #{gen_num} Summary:")
    IO.puts("  Episodes: #{history.episodes_created}")
    IO.puts("  Discoveries: #{history.discoveries_made}")
    IO.puts("  Adaptations: #{history.adaptations_adopted}/#{history.adaptations_evaluated} adopted")
    
    pred_error = case history.prediction_accuracy do
      %{average_absolute_error: err} when is_number(err) -> Float.round(err * 100, 2)
      _ -> "N/A"
    end
    IO.puts("  Prediction Error: #{pred_error}%")
    
    IO.puts("  CAI: #{history.civilization_adaptation_index || "N/A"}")
    IO.puts("  Scientific Capital: #{round(history.scientific_capital)}")
  end

  defp save_checkpoint(state, output_dir, gen_num) do
    checkpoint_path = Path.join(output_dir, "checkpoint_gen#{gen_num}.json")
    # Simplified checkpoint - in production would serialize full state
    File.write!(checkpoint_path, Jason.encode!(%{
      generation: gen_num,
      total_episodes: state.total_episodes,
      total_discoveries: state.total_discoveries,
      scientific_capital: state.scientific_capital,
      timestamp: DateTime.utc_now(),
      # Phase D: machine-readable evidence labeling travels with checkpoints
      stage_evidence_labels: state.stage_evidence_labels,
      stage_provenance: Map.get(state, :stage_provenance, %{}),
      run_authorized: state.run_authorized
    }))
  end

  defp generate_final_reports(histories, output_dir) do
    IO.puts("\n📄 Generating final reports...")

    # Generate harness-only trend analysis; outputs are not certification evidence.
    generate_trend_report(histories, output_dir)

    # CSV export helper is a no-op; do not claim CSV persistence from this call.
    generate_csv_exports(histories, output_dir)

    IO.puts("  ✓ Reports saved to #{output_dir}")
  end

  defp generate_trend_report(histories, output_dir) do
    report_path = Path.join(output_dir, "recursive_evolution_report.md")

    content = """
    # Recursive Evolution Report - Stage 6 SIMULATION HARNESS

    **Evidence status**: SIMULATED OUTPUT — NOT REAL-ENGINE VALIDATION
    **Generations processed by harness**: #{length(histories)}
    **Date**: #{DateTime.utc_now() |> DateTime.to_iso8601()}

    This report summarizes synthetic/simulated harness output. It is not evidence of
    real research execution, empirical self-improvement, calibrated predictions,
    constitutional compliance, or complete provenance. Some metrics are random,
    constant, simplified, or stub-derived. The real Stage 3-5 engines are not invoked.

    ---

    ## Longitudinal Trends

    ### Research Velocity
    - First 10 gens avg: #{calculate_avg(histories, :research_velocity, 0..9)}
    - Last 10 gens avg: #{calculate_avg(histories, :research_velocity, -10..-1//1)}
    - Trend: #{trend_direction(histories, :research_velocity)}

    ### Prediction Reliability
    - First 10 gens avg: #{calculate_avg(histories, :prediction_reliability, 0..9)}
    - Last 10 gens avg: #{calculate_avg(histories, :prediction_reliability, -10..-1//1)}
    - Trend: #{trend_direction(histories, :prediction_reliability)}

    ### Civilization Adaptation Index
    - First 10 gens avg: #{calculate_avg(histories, :civilization_adaptation_index, 0..9)}
    - Last 10 gens avg: #{calculate_avg(histories, :civilization_adaptation_index, -10..-1//1)}
    - Trend: #{trend_direction(histories, :civilization_adaptation_index)}

    ### Research Debt
    - First 10 gens avg: #{calculate_avg(histories, :research_debt, 0..9)}
    - Last 10 gens avg: #{calculate_avg(histories, :research_debt, -10..-1//1)}
    - Trend: #{trend_direction(histories, :research_debt, :inverse)}

    ### Scientific Capital
    - Total accumulated: #{Enum.sum(Enum.map(histories, & &1.scientific_capital))}
    - Final generation: #{List.last(histories).scientific_capital}
    - Growth rate: #{calculate_growth_rate(histories, :scientific_capital)}%

    ---

    ## Constitutional Compliance

    - Total violations: #{Enum.sum(Enum.map(histories, & &1.constitutional_violations))}
    - Lifecycle completeness: #{calculate_avg(histories, :lifecycle_completeness_pct, 0..-1//1)}%
    - Rollback frequency: #{calculate_avg(histories, :rollback_frequency, 0..-1//1) * 100}%

    ---

    ## Conclusion

    Harness trend classification: #{assess_improvement(histories)} (SIMULATED INPUTS; NOT AN EMPIRICAL CLAIM).

    The reported trends derive from this harness's simulated, randomized, constant,
    simplified, or stub-derived values. They do not establish real improvement.
    Provenance completeness and durable persistence have not been established.
    """

    File.write!(report_path, content)
  end

  defp generate_csv_exports(_histories, _output_dir) do
    # Main generation history CSV already written during execution
    # Additional specialized CSVs can be generated here
    IO.puts("  ✓ Generation history CSV complete")
  end

  # ──────────────────────────────────────────────
  # Analysis Helpers
  # ──────────────────────────────────────────────

  defp calculate_avg(histories, field, range) do
    subset = Enum.slice(histories, range)
    values = Enum.map(subset, fn h -> Map.get(h, field) || 0 end)
    if length(values) > 0 do
      Float.round(Enum.sum(values) / length(values), 3)
    else
      0.0
    end
  end

  defp trend_direction(histories, field, mode \\ :normal) do
    _first_half = Enum.slice(histories, 0..4)
    _last_half = Enum.slice(histories, -5..-1)

    first_avg = calculate_avg(histories, field, 0..4)
    last_avg = calculate_avg(histories, field, -5..-1)

    cond do
      mode == :inverse and last_avg < first_avg -> "↓ Improving"
      mode == :inverse and last_avg > first_avg -> "↑ Worsening"
      last_avg > first_avg * 1.1 -> "↑ Improving"
      last_avg < first_avg * 0.9 -> "↓ Declining"
      true -> "→ Stable"
    end
  end

  defp calculate_growth_rate(histories, field) do
    first = List.first(histories) |> Map.get(field, 0)
    last = List.last(histories) |> Map.get(field, 0)

    if first > 0 do
      Float.round((last - first) / first * 100, 2)
    else
      0.0
    end
  end

  defp assess_improvement(histories) do
    cai_trend = trend_direction(histories, :civilization_adaptation_index)
    prediction_trend = trend_direction(histories, :prediction_reliability)

    cond do
      String.contains?(cai_trend, "Improving") and String.contains?(prediction_trend, "Improving") ->
        "measurable self-improvement"
      String.contains?(cai_trend, "Improving") ->
        "partial improvement in civilizational coordination"
      true ->
        "stable operation with room for optimization"
    end
  end
end
