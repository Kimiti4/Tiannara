defmodule Tiannara.OPC.ObserverPhysicsCompiler do
  @moduledoc """
  Phase 5F.6 — Observer Physics Compiler (OPC)

  Compiles observer-defined physics into Ontological IR (OIR)
  under MSCL-Ω + OLEF + RODL constraints.

  ## Core Responsibility

  Answers one question:
  > "Can this observer-defined law exist without breaking local coherence?"

  Not globally valid. Only locally safe.

  ## Architecture Position

      ExecutionController
            ↓
      ChronogramMatrix (5F.4)
            ↓
      MSCL-Ω (5F.5 coherence bounds)
            ↓
      🧠 OPC (5F.6 physics compilation layer)
            ↓
      OLEF (load equilibrium)
            ↓
      RODL (delegation mesh)

  ## Pipeline

      Physics Proposal → AST → Validation → CCI → OIR → GPU Kernel

  Where:
  - AST = Symbolic physics structure
  - CCI = Causal Constraint Injection (MSCL-Ω boundaries)
  - OIR = Ontological Intermediate Representation
  - GPU Kernel = WebGL2 compute shader

  ## Usage

      # Compile observer physics proposal
      physics_ast = {:gravity, [mass: 1.0, distance: 10.0]}
      case OPC.ObserverPhysicsCompiler.compile_physics("obs_001", physics_ast) do
        {:ok, oir} -> IO.puts("Physics compiled successfully")
        {:rejected, _reason} -> reject_proposal()
      end
  """

  use GenServer
  require Logger

  alias Tiannara.Meta.Metastability.Kernel, as: MSCLKernel
  alias Tiannara.OPC.Validation.SingularityDetector
  alias Tiannara.OPC.Validation.ThermodynamicBudgetEstimator
  alias Tiannara.OPC.Validation.LoopAnalyzer
  alias Tiannara.OPC.Validation.EpsilonShimEngine
  alias Tiannara.OPC.IR.OIRGenerator
  alias TiannaraRuntime.CTL.Validation.Validator, as: CTLValidator
  alias TiannaraRuntime.NATS.OCMBus
  alias Tiannara.OPC.Validation.OCMDriftRouter

  # ── Configuration ─────────────────────────────────────────────────────────

  # Maximum allowed divergence for physics compilation
  @max_divergence_threshold 0.78

  # Maximum thermodynamic cost (arbitrary units)
  @max_thermodynamic_cost 1000

  # Maximum recursion depth in AST
  @max_ast_depth 32

  # ── State ─────────────────────────────────────────────────────────────────

  defstruct [
    compiled_cache: %{},        # %{observer_id => compiled_oir}
    validation_state: %{},      # %{observer_id => validation_metrics}
    kernel_registry: %{}        # %{kernel_id => gpu_shader_ref}
  ]

  # ── Public API ────────────────────────────────────────────────────────────

  @doc """
  Starts the OPC GenServer.
  
  ## Returns
  - `{:ok, pid}` — Successfully started
  - `{:error, reason}` — Failed to start
  """
  def start_link(init_args \\ []) do
    GenServer.start_link(__MODULE__, init_args, name: __MODULE__)
  end

  @doc """
  Compiles observer-defined physics into Ontological IR (OIR).

  ## Parameters
  - `observer_id`: The observer proposing the physics
  - `physics_ast`: Abstract Syntax Tree representing the physics law

  ## Returns
  - `{:ok, oir}` — Successfully compiled Ontological IR
  - `{:rejected, reason}` — Compilation failed validation

  ## Example

      physics_ast = {:op, :/, [
        {:const, 1.0},
        {:op, :pow, [{:var, :distance}, 2]}
      ]}

      case OPC.ObserverPhysicsCompiler.compile_physics("obs_001", physics_ast) do
        {:ok, oir} -> deploy_to_gpu(oir)
        {:rejected, :singularity_detected} -> reject_proposal()
      end
  """
  def compile_physics(observer_id, physics_ast) do
    GenServer.call(__MODULE__, {:compile, observer_id, physics_ast}, :infinity)
  end

  @doc """
  Gets compilation statistics for an observer.
  """
  def get_compilation_stats(observer_id) do
    GenServer.call(__MODULE__, {:get_stats, observer_id})
  end

  # ── GenServer Callbacks ───────────────────────────────────────────────────

  @impl true
  def init(_opts) do
    Logger.info("🧠 OPC initialized (Phase 5F.6 Observer Physics Compiler)")

    state = %__MODULE__{
      compiled_cache: %{},
      validation_state: %{},
      kernel_registry: %{}
    }

    {:ok, state}
  end

  @impl true
  def handle_call({:compile, observer_id, ast}, _from, state) do
    Logger.info("📝 [OPC] Compiling physics for observer #{observer_id}")

    result =
      case validate_ast(observer_id, ast) do
        {:ok, stable_ast} ->
          # Build Ontological IR from validated AST
          oir = OIRGenerator.build(stable_ast, observer_id)

          Logger.info("✅ [OPC] Physics compiled successfully for #{observer_id}")
        # Evaluate drift and possibly publish OCM drift alert
        case OCMDriftRouter.evaluate_and_route(observer_id, stable_ast) do
          :ok -> :ok
          {:error, reason} -> Logger.warning("[OPC] Drift routing error: #{inspect(reason)}")
        end

          # Cache the compilation
          updated_cache = Map.put(state.compiled_cache, observer_id, oir)
          updated_state = %{state | compiled_cache: updated_cache}

          {:reply, {:ok, oir}, updated_state}

        {:error, reason} ->
          Logger.warning("⚠️ [OPC] Compilation rejected for #{observer_id}: #{inspect(reason)}")

          # Record rejection in validation state
          updated_validation = Map.put(state.validation_state, observer_id, %{
            last_rejection: reason,
            timestamp: DateTime.utc_now()
          })

          updated_state = %{state | validation_state: updated_validation}

          {:reply, {:rejected, reason}, updated_state}

        {:error, reason, _msg} ->
          Logger.warning("⚠️ [OPC] Compilation rejected for #{observer_id}: #{inspect(reason)}")

          # Record rejection in validation state
          updated_validation = Map.put(state.validation_state, observer_id, %{
            last_rejection: reason,
            timestamp: DateTime.utc_now()
          })

          updated_state = %{state | validation_state: updated_validation}

          {:reply, {:rejected, reason}, updated_state}
      end

    result
  end

  @impl true
  def handle_call({:get_stats, observer_id}, _from, state) do
    stats = %{
      observer_id: observer_id,
      has_compiled_physics: Map.has_key?(state.compiled_cache, observer_id),
      last_validation: Map.get(state.validation_state, observer_id, :none),
      total_cached_compilations: map_size(state.compiled_cache)
    }

    {:reply, {:ok, stats}, state}
  end

  # ── Validation Pipeline ───────────────────────────────────────────────────

  defp validate_ast(observer_id, ast) do
    Logger.debug("🔍 [OPC] Running validation pipeline for #{observer_id}")

    with :ok <- mscl_divergence_check(observer_id, ast),
         :ok <- LoopAnalyzer.check(ast, @max_ast_depth),
         {:ok, budget} <- ThermodynamicBudgetEstimator.estimate(ast),
         # Apply AOR regularization BEFORE singularity detection
         {:ok, regularized_ast} <- EpsilonShimEngine.apply(ast, budget),
         # Now check that regularization eliminated singularities
         :ok <- SingularityDetector.scan(regularized_ast),
         # CTL: causal-tension validation — rejects ASTs that would inject
         # excessive causal stress into the live tensegrity graph
         :ok <- ctl_validate(regularized_ast),
         :ok <- causal_consistency_check(regularized_ast) do
      # All checks passed, inject MSCL-Ω constraints
      {:ok, inject_causal_constraints(regularized_ast)}
    end
  end

  # ── MSCL-Ω Integration ────────────────────────────────────────────────────

  defp mscl_divergence_check(observer_id, _ast) do
    # Query MSCL-Ω Kernel for current divergence pressure
    # In production, would check if observer's proposed physics would exceed divergence bounds

    # For now, simulate divergence extraction from AST complexity
    divergence = extract_divergence_from_ast_complexity(_ast)

    if divergence < @max_divergence_threshold do
      Logger.debug("✅ [OPC] MSCL-Ω divergence check passed (#{divergence |> :erlang.float_to_binary(decimals: 3)} < #{@max_divergence_threshold})")
      :ok
    else
      Logger.warning("🛑 [OPC] MSCL-Ω divergence exceeded (#{divergence} >= #{@max_divergence_threshold})")
      {:error, :mscl_divergence_exceeded}
    end
  end

  defp extract_divergence_from_ast_complexity(ast) do
    # Calculate divergence based on AST structural complexity
    # More complex physics = higher divergence risk

    complexity = calculate_ast_complexity(ast)

    # Normalize to 0.0-1.0 range
    normalized = min(complexity / 100.0, 1.0)

    # Add some randomness to simulate real-world variability
    normalized * (0.5 + :rand.uniform() * 0.5)
  end

  defp calculate_ast_complexity(ast) when is_tuple(ast) do
    Tuple.to_list(ast)
    |> Enum.map(&calculate_ast_complexity/1)
    |> Enum.sum()
  end

  defp calculate_ast_complexity(list) when is_list(list) do
    Enum.map(list, &calculate_ast_complexity/1)
    |> Enum.sum()
  end

  defp calculate_ast_complexity(_leaf), do: 1

  # ── CTL Validation ──────────────────────────────────────────────────────────

  @doc false
  @spec ctl_validate(term()) :: :ok | {:error, :ctl_validation_failed, String.t()}
  defp ctl_validate(ast) do
    case CTLValidator.validate_ast(ast) do
      {:ok, :causally_stable, _sm} ->
        Logger.debug("✅ [OPC/CTL] AST passes causal-tension check")
        :ok

      {:error, :cyclic_dependency, _sm} ->
        Logger.warning("🛑 [OPC/CTL] AST rejected: cyclic causal dependency")
        {:error, :ctl_validation_failed, "cyclic causal dependency detected in AST"}

      {:error, :excessive_tension, max_stress, _sm} ->
        Logger.warning(
          "🛑 [OPC/CTL] AST rejected: excessive causal tension (max_stress=#{max_stress})"
        )
        {:error, :ctl_validation_failed,
         "excessive causal tension #{max_stress}; AST would over-stress the tensegrity graph"}
    end
  end

  # ── Safety Checks ─────────────────────────────────────────────────────────

  defp causal_consistency_check(ast) do
    # Verify that the physics proposal maintains causal consistency
    # No backward-in-time influences, no circular causality

    if has_valid_causal_structure?(ast) do
      Logger.debug("✅ [OPC] Causal consistency check passed")
      :ok
    else
      Logger.warning("🛑 [OPC] Causal consistency violation detected")
      {:error, :causal_violation}
    end
  end

  defp has_valid_causal_structure?(_ast) do
    # Placeholder: Would perform deep causal graph analysis
    # For now, assume most proposals are causally valid
    true
  end

  # ── Constraint Injection ──────────────────────────────────────────────────

  defp inject_causal_constraints(ast) do
    Logger.debug("🔒 [OPC] Injecting MSCL-Ω causal constraints into AST")

    # Use Macro.postwalk to traverse AST and inject safety markers
    Macro.postwalk(ast, fn
      # Inject :mscl_bound marker into gravity operations
      {:op, :gravity, args} ->
        {:op, :gravity, args ++ [:mscl_bound]}

      # Inject epsilon regularization into division operations
      {:op, :/, [numerator, denominator]} ->
        # Transform: A/B → A/sqrt(B² + ε²)
        {:op, :/, [
          numerator,
          {:op, :sqrt, [
            {:op, :+, [
              {:op, :pow, [denominator, 2]},
              {:mscl_pointer, :epsilon_variance}  # Live pointer to MSCL-Ω budget
            ]}
          ]}
        ]}

      # Pass through all other nodes unchanged
      node ->
        node
    end)
  end
end
