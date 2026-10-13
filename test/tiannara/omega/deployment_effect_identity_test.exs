defmodule Tiannara.Omega.DeploymentEffectIdentityTest do
  use ExUnit.Case, async: true

  alias Tiannara.Omega.{DeploymentGateway, PatchGenerator}
  alias Tiannara.Omega.DeploymentGateway.DeploymentRegistry

  test "same candidate produces the same effect identity" do
    candidate = PatchGenerator.Candidate.new(:code_patch, :proposal, %{file: "a"})

    assert DeploymentGateway.effect_identity(candidate) ==
             DeploymentGateway.effect_identity(candidate)
  end

  test "distinct candidate content produces distinct effect identities" do
    candidate_a = PatchGenerator.Candidate.new(:code_patch, :proposal, %{file: "a"})
    candidate_b = PatchGenerator.Candidate.new(:code_patch, :proposal, %{file: "b"})

    refute DeploymentGateway.effect_identity(candidate_a) ==
             DeploymentGateway.effect_identity(candidate_b)
  end

  test "registry rejects an unproven effect for an existing authorization" do
    path = Path.join(System.tmp_dir!(), "tiannara-deployment-effect-#{System.unique_integer([:positive])}")
    on_exit(fn -> File.rm(path) end)

    assert :ok = DeploymentRegistry.record_deployment(:auth, "effect-a", :deployment, path)
    assert :same_effect = DeploymentRegistry.deployment_status(:auth, "effect-a", path)
    assert :different_effect = DeploymentRegistry.deployment_status(:auth, "effect-b", path)
  end
end