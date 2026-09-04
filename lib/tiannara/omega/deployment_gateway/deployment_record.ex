defmodule Tiannara.Omega.DeploymentGateway.DeploymentRecord do
  @moduledoc "An auditable record of a deployment."
  @enforce_keys [:deployment_id, :candidate_id, :granted_by]
  defstruct [:deployment_id, :candidate_id, :granted_by, :authorization_id,
             :deployed_at, :lineage, :status]
end