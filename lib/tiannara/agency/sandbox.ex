defmodule Tiannara.Agency.Sandbox do
  @moduledoc "Execution sandbox boundary. Never fabricates experimental outcomes."
  alias Tiannara.Agency.Models.Experiment

  def available?, do: false

  def run_experiment(%Experiment{}), do: {:error, :real_experiment_executor_unavailable}
end
