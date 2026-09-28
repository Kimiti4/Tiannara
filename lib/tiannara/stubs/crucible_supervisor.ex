defmodule Tiannara.ASC.Crucible.Supervisor do
  @moduledoc "Concrete Crucible entry point; delegates project validation when enough evidence is supplied."

  def run(%{genome: genome, artifact_path: artifact_path} = project) do
    case Tiannara.ASC.Crucible.Validator.validate(genome, artifact_path, project) do
      {:ok, result} -> {:ok, %{status: if(result.valid?, do: :validated, else: :rejected), validation: result}}
      other -> other
    end
  end
  def run(_), do: {:error, :insufficient_validation_inputs}
end
