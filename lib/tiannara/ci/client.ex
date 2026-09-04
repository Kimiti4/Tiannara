defmodule Tiannara.CI.Client do
  @moduledoc """
  Bridges a `CI.Provider` into the function-map client expected by
  `Sandbox.Backend.CI`. This is how a real CI provider plugs into the Ω.4
  sandbox without the sandbox knowing which provider it is.

  Constitutional basis: Replaceability, Modularity ("explicit interfaces,
  minimal coupling").
  """

  def from_provider(provider, config) do
    %{
      prepare_workspace: fn baseline -> {:ok, %{baseline: baseline}} end,

      apply_patch: fn workspace, patch -> {:ok, Map.put(workspace, :patch, patch)} end,

      submit_job: fn _workspace, job_type, spec ->
        provider.trigger_workflow(config, %{job_type: job_type, spec: describe(spec)})
      end,

      job_status: fn run_id ->
        case provider.run_status(config, run_id) do
          {:ok, status} -> status
          {:error, _} -> :failed
        end
      end,

      fetch_result: fn run_id ->
        case provider.run_conclusion(config, run_id) do
          {:ok, {output, code}} -> {:ok, output, code}
          {:error, _} = e -> e
        end
      end,

      cleanup: fn _workspace -> :ok end
    }
  end

  defp describe(spec) when is_map(spec), do: Map.take(spec, [:command, :args, :metric])
  defp describe(spec), do: %{spec: spec}
end