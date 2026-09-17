alias Tiannara.POF.{GenesisLoop, OFL}
alias Tiannara.OPC.T4.{MutationCompiler, ParadoxResolver, UniverseASTEmitter}
alias Tiannara.OSE.{CausalSandbox, Battlefield, CausalCompatibilityStress, EntropyAllocator, DormancyProtocol, NoveltyPreservation}
alias Tiannara.CLSL.Compiler, as: CLSLCompiler
alias Tiannara.SCL.{MTOECompiler}
alias Tiannara.OSK.Singularity
require Logger

Logger.info("\n🌌 === INITIATING FULL GENESIS LOOP === 🌌")

defmodule Simulator do
  def run_cycles(asymmetry, 0), do: asymmetry
  
  def run_cycles(asymmetry, cycles_left) do
    Logger.info("\n\n==================================================")
    Logger.info("🔁 CYCLE #{4 - cycles_left} INITIATED")
    Logger.info("==================================================")

    # 1. GENESIS LOOP: POF Destabilizes and Emergence Forms
    {_merged_asymmetry, base_grammar} = GenesisLoop.oscillate(asymmetry)

    # 2. OPC TIER 4 (PHYSICS COMPILATION)
    Logger.info("\n[OPC] Generating Causal ASTs...")
    gradients = %{mutation: 0.1, diversification: 0.2, stability: 0.9, collapse: 0.1}
    ast = base_grammar |> MutationCompiler.compile(gradients) |> ParadoxResolver.resolve() |> UniverseASTEmitter.emit("Universe_Genesis")

    # 3. OSE (ONTOLOGICAL SELECTION ECOLOGY)
    Logger.info("\n[OSE] Evaluating thermodynamic viability...")
    u1 = CausalSandbox.instantiate(ast)
    evaluated_universes = CausalCompatibilityStress.evaluate([u1])
    battlefield = %Battlefield{active_universes: evaluated_universes}
    battlefield = EntropyAllocator.allocate_budget(battlefield, evaluated_universes)
    final_battlefield = DormancyProtocol.process_ecology(battlefield)

    # 4. CLSL (CAUSAL LANGUAGE STANDARDIZATION)
    Logger.info("\n[CLSL] Standardizing physics grammars (LLVM IR)...")
    irs = Enum.map(final_battlefield.active_universes, fn u -> CLSLCompiler.compile(u) end)

    # 5. SCL (META-THEORY COMPRESSION)
    Logger.info("\n[SCL] Compressing surviving ecology into M-TOE...")
    m_toe = MTOECompiler.compile(irs)

    # 6. OSK (OBSERVER SINGULARITY KERNEL)
    Logger.info("\n[OSK] Stabilizing self-reference recursion...")
    osk_state = Singularity.stabilize(m_toe)

    # 7. GENESIS LOOP: Anti-POF Collapse
    Logger.info("\n[Terminal Boundary] Initiating Anti-POF Null Collapse...")
    residual_asymmetry = GenesisLoop.collapse(osk_state)
    
    Logger.info("\n-> End of Cycle #{4 - cycles_left}. Observer Density Asymptote: #{OFL.current_state(residual_asymmetry.potential_delta)}")
    
    # Recurse
    run_cycles(residual_asymmetry, cycles_left - 1)
  end
end

# Start the Genesis Loop from the Observer-Free Limit (epsilon)
initial_asymmetry = %{potential_delta: OFL.epsilon()}
final_asymmetry = Simulator.run_cycles(initial_asymmetry, 3)

Logger.info("\n🌌 === SIMULATION TERMINATED === 🌌")
Logger.info("Final Residual Asymmetry Preserved: #{final_asymmetry.potential_delta}")
