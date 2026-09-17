defmodule TiannaraRuntime.WorldModel.Pipeline.PipelineOrchestrator do
  @moduledoc """
  Phase 17.2 — Pipeline Orchestrator.

  Chains all 10 pipeline stages end-to-end, passing stage outputs
  as inputs to subsequent stages. Returns the complete pipeline
  result including the final world model and certificate.
  """

  alias TiannaraRuntime.WorldModel.Pipeline.{
    EvidenceIngestion,
    VariableSpecification,
    StructureLearning,
    EquationLearning,
    ParameterEstimation,
    ModelAssembly,
    ModelValidation,
    ModelCertification,
    ModelDeployment
  }

  @doc """
  Run the full model construction pipeline.

  ## Options
    - `:domain` — research domain atom (required)
    - `:name` — model name (required)
    - `:time_window` — %{start: iso, end: iso}
    - `:observation_ids` — explicit observation IDs
    - `:metadata` — extra metadata for the model
    - `:held_out_evidence` — evidence set for validation (default: %{})

  ## Returns
    `{:ok, %{evidence_set: map(), variable_set: map(), structure_output: map(),
             equation_output: map(), parameter_output: map(), model: WorldModel.t(),
             validation_metrics: [map()], certificate: ModelCertificate.t()}}`
  """
  @spec run_pipeline(keyword()) :: {:ok, map()} | {:error, term()}
  def run_pipeline(opts \\ []) do
    domain = Keyword.get(opts, :domain)
    name = Keyword.get(opts, :name)

    with {:ok, evidence_set} <- stage(:ingest, fn ->
           EvidenceIngestion.ingest_evidence(Keyword.take(opts, [:domain, :time_window, :observation_ids, :metadata]))
         end),
         {:ok, variable_set} <- stage(:specify_variables, fn ->
           VariableSpecification.specify_variables(evidence_set)
         end),
         {:ok, structure_output} <- stage(:learn_structure, fn ->
           StructureLearning.learn_structure(variable_set, evidence_set)
         end),
         {:ok, equation_output} <- stage(:learn_equations, fn ->
           EquationLearning.learn_equations(structure_output.causal_graph, evidence_set)
         end),
         {:ok, parameter_output} <- stage(:estimate_parameters, fn ->
           ParameterEstimation.estimate_parameters(equation_output.equation_system, evidence_set)
         end),
         {:ok, model} <- stage(:assemble, fn ->
           ModelAssembly.assemble_model(%{
             name: name,
             domain: domain,
             variables: variable_set.variables,
             variable_root: variable_set.variable_root,
             causal_graph: structure_output.causal_graph,
             structure_root: structure_output.structure_root,
             equation_system: equation_output.equation_system,
             equation_root: equation_output.equation_root,
             parameters: parameter_output.parameters,
             parameter_root: parameter_output.parameter_root,
             evidence_roots: [evidence_set.evidence_root],
             metadata: Keyword.get(opts, :metadata, %{})
           })
         end),
         {:ok, validation_metrics} <- stage(:validate, fn ->
           held_out = Keyword.get(opts, :held_out_evidence, %{})
           ModelValidation.validate_model(model, held_out)
         end),
         {:ok, certificate} <- stage(:certify, fn ->
           ModelCertification.certify_model(model)
         end),
         {:ok, :deployed} <- stage(:deploy, fn ->
           ModelDeployment.deploy_model(model)
         end) do
      {:ok, %{
        evidence_set: evidence_set,
        variable_set: variable_set,
        structure_output: structure_output,
        equation_output: equation_output,
        parameter_output: parameter_output,
        model: model,
        validation_metrics: validation_metrics,
        certificate: certificate
      }}
    end
  end

  defp stage(_name, fun) do
    case fun.() do
      {:ok, result} -> {:ok, result}
      {:error, reason} -> {:error, reason}
    end
  end
end
