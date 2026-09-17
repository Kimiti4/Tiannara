defmodule TiannaraRuntime.WorldModel.Behaviours.Pipeline do
  @moduledoc """
  Phase 17 — Pipeline behaviour.

  Defines the contract for the world model construction and lifecycle pipeline.
  Every stage is deterministic, replayable, and archaeologically logged.

  Pipeline stages:
    1. ingest_evidence   — fetch and fingerprint observations
    2. specify_variables — define variable types, bounds, and roles
    3. learn_structure   — discover causal graph structure from evidence
    4. learn_equations   — derive governing equations from structure + evidence
    5. estimate_params   — estimate parameter values with uncertainty
    6. assemble_model    — compose all components into a WorldModel
    7. validate_model    — validate predictions against held-out evidence
    8. certify_model     — issue constitutional certificate
    9. deploy_model      — publish for operational use
    10. evolve_model     — update model with new evidence
  """

  @doc "Stage 1: Ingest and fingerprint evidence from the Observation Registry."
  @callback ingest_evidence(evidence_set :: map()) ::
              {:ok, map()}
              | {:error, String.t()}

  @doc "Stage 2: Extract and type variables from evidence."
  @callback specify_variables(evidence_set :: map()) ::
              {:ok, %{variables: [TiannaraRuntime.WorldModel.Ontology.Variable.t()], variable_root: String.t()}}
              | {:error, String.t()}

  @doc "Stage 3: Learn causal graph structure from variables and evidence."
  @callback learn_structure(
              variable_set :: map(),
              evidence_set :: map()
            ) ::
              {:ok, %{causal_graph: TiannaraRuntime.WorldModel.Ontology.CausalGraph.t(), structure_root: String.t()}}
              | {:error, String.t()}

  @doc "Stage 4: Learn or assign governing equations from structure and evidence."
  @callback learn_equations(
              causal_graph :: TiannaraRuntime.WorldModel.Ontology.CausalGraph.t(),
              evidence_set :: map()
            ) ::
              {:ok, %{equation_system: TiannaraRuntime.WorldModel.Ontology.EquationSystem.t(), equation_root: String.t()}}
              | {:error, String.t()}

  @doc "Stage 5: Estimate parameters from equations and evidence."
  @callback estimate_parameters(
              equation_system :: TiannaraRuntime.WorldModel.Ontology.EquationSystem.t(),
              evidence_set :: map()
            ) ::
              {:ok, %{parameters: [TiannaraRuntime.WorldModel.Ontology.Parameter.t()], parameter_root: String.t()}}
              | {:error, String.t()}

  @doc "Stage 6: Assemble all components into a complete WorldModel."
  @callback assemble_model(components :: map()) ::
              {:ok, TiannaraRuntime.WorldModel.Ontology.WorldModel.t()}
              | {:error, String.t()}

  @doc "Stage 7: Validate model predictions against held-out evidence."
  @callback validate_model(
              model :: TiannaraRuntime.WorldModel.Ontology.WorldModel.t(),
              evidence_set :: map()
            ) ::
              {:ok, [TiannaraRuntime.WorldModel.Ontology.ValidationEvidence.t()]}
              | {:error, String.t()}

  @doc "Stage 8: Issue constitutional certificate for a validated model."
  @callback certify_model(model :: TiannaraRuntime.WorldModel.Ontology.WorldModel.t()) ::
              {:ok, TiannaraRuntime.WorldModel.Ontology.ModelCertificate.t()}
              | {:error, String.t()}

  @doc "Stage 9: Deploy a certified model for operational use."
  @callback deploy_model(model :: TiannaraRuntime.WorldModel.Ontology.WorldModel.t()) ::
              {:ok, :deployed}
              | {:error, String.t()}

  @doc "Stage 10: Evolve a model with new evidence (creates new version)."
  @callback evolve_model(
              model :: TiannaraRuntime.WorldModel.Ontology.WorldModel.t(),
              new_evidence :: map()
            ) ::
              {:ok, TiannaraRuntime.WorldModel.Ontology.WorldModel.t()}
              | {:error, String.t()}
end
