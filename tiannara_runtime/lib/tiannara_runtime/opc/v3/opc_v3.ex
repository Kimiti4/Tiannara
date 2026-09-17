defmodule Tiannara.OPC.V3 do
  @moduledoc """
  OPC v3 - Ontological Physics Compiler Version 3
  Clean rebuild with strict intermediate representation pipeline
  
  ## Core Principle
  "No raw syntax survives parsing. Everything becomes typed IR before execution."
  
  ## Pipeline
  SOURCE STRING -> Tokenizer -> Parser -> OIR Builder -> Validator -> Normalizer -> Compiler Passes -> Execution IR -> Runtime
  """

  alias Tiannara.OPC.V3.Parser
  alias Tiannara.OPC.V3.IR.{OIR, Builder}
  alias Tiannara.OPC.V3.IR.{Validator, ASTNormalizer, DepthCalculator}
  alias Tiannara.OPC.V3.Compiler
  alias Tiannara.OPC.V3.Compiler.{ConstantFold, DepthAnalysis, SafetyInjector, TensorLift}
  alias Tiannara.OPC.V3.IR.EIR
  alias Tiannara.OPC.V3.Runtime.ExecutionEngine
  alias Tiannara.OPC.V3.GPU.GPUExecutionEngine
  alias Tiannara.OPC.V3.OLEF
  alias Tiannara.OPC.V3.OLEF.{PressureMesh, DistributedObserver, WebGLRenderer, ODEF, RODL, AutonomousFramework}

  @doc """
  Compiles a source string through the entire OPC v3 pipeline
  """
  def compile(source) do
    try do
      # Step 1: Parse source to raw syntax tree
      {:ok, raw_syntax_tree, _remaining} = Parser.parse(source)
      
      # Step 2: Build OIR from raw syntax tree
      oir = Builder.build(raw_syntax_tree)
      
      # Step 3: Validate OIR structure
      case Validator.validate(oir) do
        :ok -> :ok
        {:error, reason} -> raise "IR validation failed: #{inspect(reason)}"
      end
      
      # Step 4: Normalize OIR to canonical form
      normalized_oir = ASTNormalizer.normalize(oir)
      
      # Step 5: Apply compiler passes
      processed_oir = 
        normalized_oir
        |> ConstantFold.apply()
        |> DepthAnalysis.apply()
        |> SafetyInjector.apply()
        |> TensorLift.apply()
      
      # Step 6: Emit execution-ready IR
      eir = convert_to_eir(processed_oir)
      
      # Step 7: Execute and return result
      ExecutionEngine.execute(eir)
    rescue
      error ->
        {:error, Exception.message(error)}
    end
  end

  @doc """
  Compiles and executes on GPU when possible
  """
  def compile_for_gpu(source) do
    try do
      # Step 1: Parse source to raw syntax tree
      {:ok, raw_syntax_tree, _remaining} = Parser.parse(source)
      
      # Step 2: Build OIR from raw syntax tree
      oir = Builder.build(raw_syntax_tree)
      
      # Step 3: Validate OIR structure
      case Validator.validate(oir) do
        :ok -> :ok
        {:error, reason} -> raise "IR validation failed: #{inspect(reason)}"
      end
      
      # Execute on GPU
      GPUExecutionEngine.execute_on_gpu(oir)
    rescue
      error ->
        {:error, Exception.message(error)}
    end
  end

  # Helper function to convert OIR to EIR
  defp convert_to_eir(%OIR{type: :number, value: value}) do
    %EIR{
      type: :constant,
      op: :load,
      operands: [value],
      result_type: :float,
      metadata: %{}
    }
  end

  defp convert_to_eir(%OIR{type: :binary, op: op, children: [left, right]}) do
    left_eir = convert_to_eir(left)
    right_eir = convert_to_eir(right)
    
    %EIR{
      type: :operation,
      op: op,
      operands: [extract_value(left_eir), extract_value(right_eir)],
      result_type: :float,
      metadata: %{}
    }
  end

  defp convert_to_eir(%OIR{type: :unary, op: op, children: [operand]}) do
    operand_eir = convert_to_eir(operand)
    
    %EIR{
      type: :operation,
      op: op,
      operands: [extract_value(operand_eir)],
      result_type: :float,
      metadata: %{}
    }
  end

  defp convert_to_eir(%OIR{type: :function, op: op, children: args}) do
    arg_values = Enum.map(args, fn arg -> extract_value(convert_to_eir(arg)) end)
    
    %EIR{
      type: :function_call,
      op: op,
      operands: arg_values,
      result_type: :float,
      metadata: %{}
    }
  end

  defp extract_value(%EIR{operands: [value]}), do: value
  defp extract_value(_), do: 0.0

  @doc """
  Validates that the OPC v3 pipeline is functioning correctly
  """
  def health_check do
    # Test a simple expression
    test_result = compile("2 + 3")
    
    case test_result do
      {:ok, _result} -> 
        {:ok, %{status: :healthy, pipeline: :opc_v3_active, version: "3.0"}}
      {:error, reason} -> 
        {:error, %{status: :unhealthy, reason: reason, pipeline: :opc_v3_broken, version: "3.0"}}
    end
  end

  @doc """
  Checks GPU availability and compatibility
  """
  def gpu_health_check do
    gpu_available = GPUExecutionEngine.gpu_available?()
    context = GPUExecutionEngine.initialize_gpu_context()
    
    %{
      gpu_available: gpu_available,
      context: context,
      status: if(gpu_available, do: :ready, else: :unavailable)
    }
  end

  @doc """
  Initializes the Observer Physics Compiler with OLEF (Observer Logic Execution Framework)
  """
  def init_olef(options \\ %{}) do
    # Start the OLEF GenServer
    case OLEF.start_link(options) do
      {:ok, pid} -> 
        {:ok, %{pid: pid, status: :olef_initialized, framework: :olef_active}}
      {:error, reason} ->
        {:error, %{status: :olef_failed, reason: reason}}
    end
  end

  @doc """
  Applies cognitive pressure through the OLEF framework
  """
  def apply_cognitive_pressure(source_id, pressure_value, coordinates) do
    case Process.whereis(OLEF) do
      nil -> 
        {:error, :olef_not_running}
      _pid ->
        OLEF.apply_pressure(source_id, pressure_value, coordinates)
    end
  end

  @doc """
  Gets the current pressure field from OLEF
  """
  def get_pressure_field do
    case Process.whereis(OLEF) do
      nil -> 
        {:error, :olef_not_running}
      _pid ->
        OLEF.get_pressure_field()
    end
  end

  @doc """
  Checks equilibrium state in the cognitive pressure mesh
  """
  def get_equilibrium_state do
    case Process.whereis(OLEF) do
      nil -> 
        {:error, :olef_not_running}
      _pid ->
        OLEF.get_equilibrium_state()
    end
  end

  @doc """
  Creates a new distributed observer in the OLEF system
  """
  def register_observer(observer_spec) do
    case Process.whereis(OLEF) do
      nil -> 
        {:error, :olef_not_running}
      _pid ->
        OLEF.register_observer(observer_spec)
    end
  end

  @doc """
  Demonstrates the autonomous observer physics framework
  """
  def demonstrate_autonomous_physics do
    AutonomousFramework.demonstrate_no_central_runtime()
  end

  @doc """
  Creates a WebGL visualization of the pressure field
  """
  def visualize_pressure_field(mesh_dimensions \\ {20, 20}) do
    # Create a sample pressure mesh
    mesh = PressureMesh.new(mesh_dimensions)
    
    # Create a WebGL renderer
    renderer = WebGLRenderer.new(%{canvas_size: {800, 600}})
    
    # Render the pressure field
    case WebGLRenderer.render(renderer, mesh) do
      {:ok, render_params} ->
        {:ok, %{
          renderer: renderer,
          render_params: render_params,
          mesh: mesh,
          visualization_ready: true
        }}
      error ->
        error
    end
  end

  @doc """
  Executes observer dynamics using ODEF (Observer Dynamics Execution Framework)
  """
  def execute_observer_dynamics(duration_ms \\ 5000) do
    # Create initial configuration for ODEF
    config = %{
      mesh_dimensions: {15, 15},
      initial_observers: [
        %{id: "obs_1", position: {3, 3}, capabilities: [:observe, :adapt]},
        %{id: "obs_2", position: {12, 12}, capabilities: [:observe, :report]}
      ]
    }
    
    # Create ODEF instance
    odef = ODEF.new(config)
    
    # Execute dynamics for specified duration
    final_odef = ODEF.execute_continuously(odef, duration_ms)
    
    # Return statistics
    stats = ODEF.get_statistics(final_odef)
    
    {:ok, stats}
  end

  @doc """
  Defines and executes observer behaviors using RODL (Real-time Observer Definition Language)
  """
  def execute_rodl_program do
    # Create an example RODL program
    rodl_program = RODL.example_adaptive_swarm()
    
    # Create initial mesh and observers
    mesh = PressureMesh.new({10, 10})
    observers = [
      DistributedObserver.new(%{id: "env_1", position: {5, 5}}),
      DistributedObserver.new(%{id: "env_2", position: {6, 6}})
    ]
    
    # Activate the RODL program
    activated_rodl = RODL.activate(rodl_program, mesh, observers)
    
    # Execute several steps
    final_rodl = 
      Enum.reduce(1..10, activated_rodl, fn _, acc_rodl ->
        RODL.execute_step(acc_rodl)
      end)
    
    # Return final state
    state = RODL.get_state(final_rodl)
    
    {:ok, state}
  end
end
