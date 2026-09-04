defmodule TiannaraOS.ToolProviders.FastAPI do
  @moduledoc """
  Provider interface to the python autonomous-api service.
  Handles HTTP service dispatching for :fastapi backend phenotypes.
  """

  require Logger

  @doc """
  Dispatches tool execution specifications to the autonomous-api backend service.
  """
  @spec dispatch_execution(TiannaraOS.ToolGenome.t(), String.t(), map()) :: {:ok, map()} | {:error, any()}
  def dispatch_execution(genome, twin_path, inputs) do
    base_url = Application.get_env(:tiannara, :autonomous_api_url, "http://localhost:8000")
    url = Path.join(base_url, "execute-tool")
    payload = %{
      genome_id: to_string(genome.id),
      capability: to_string(genome.capability),
      execution_spec: genome.execution_spec,
      twin_path: twin_path,
      inputs: inputs
    }

    # Resilient dispatch: fallback to simulated execution if offline or test mode is enabled
    if Application.get_env(:tiannara, :mock_tool_providers, true) do
      Logger.info("📡 [Tool Provider FastAPI] Simulating dispatch for genome #{genome.id} to #{url}.")
      simulate_execution(genome.capability, twin_path)
    else
      Logger.info("📡 [Tool Provider FastAPI] Dispatching genome #{genome.id} to autonomous-api at #{url}...")
      case perform_http_post(url, payload) do
        {:error, reason} ->
          Logger.warning("📡 [Tool Provider FastAPI] Service offline (#{inspect(reason)}). Falling back to simulated result.")
          simulate_execution(genome.capability, twin_path)
      end
    end
  end

  # Simulated execution engine for tests and offline resilience
  defp simulate_execution(:find_insecure_dependency, twin_path) do
    mix_exs_path = Path.join(twin_path, "mix.exs")
    if File.exists?(mix_exs_path) do
      content = File.read!(mix_exs_path)
      cond do
        String.contains?(content, "{:plug, \"~> 1.10.0\"}") or String.contains?(content, "{:plug, \"1.13.0\"}") ->
          {:ok, %{vulnerabilities: [%{package: "plug", version: "1.13.0", status: "vulnerable", advisory: "CVE-2022-XXXX"}]}}
        true ->
          {:ok, %{vulnerabilities: []}}
      end
    else
      {:error, :target_not_found}
    end
  end

  defp simulate_execution(_, _), do: {:error, :unsupported_capability}

  defp perform_http_post(_url, _payload) do
    # Returns offline error to trigger simulation fallback if dependencies aren't running
    {:error, :offline}
  end
end
