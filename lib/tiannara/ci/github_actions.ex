defmodule Tiannara.CI.GitHubActions do
  @moduledoc """
  GitHub Actions CI provider with correlation token support for production-safe
  run attribution. Uses injectable HTTP for testability.

  Production contract:
    1. Generate unique correlation token
    2. Pass in workflow_dispatch inputs
    3. Match runs by correlation token

  Constitutional basis: "Maintain audit trails", "Avoid designs dependent on
  any single platform", Verification First.
  """

  @behaviour Tiannara.CI.Provider

  @impl true
  def trigger_workflow(config, inputs) do
    http = fetch_http!(config)
    url = dispatch_url(config)

    # Generate unique correlation token
    correlation_id = :crypto.strong_rand_bytes(16) |> Base.encode16(case: :lower)
    inputs = Map.put(inputs, :correlation_id, correlation_id)

    body = %{ref: config.ref, inputs: inputs}

    case http.(:post, url, auth_headers(config), body) do
      {:ok, status, _resp} when status in [200, 204] ->
        wait_for_correlation_id(config, correlation_id)

      {:ok, status, resp} ->
        {:error, {:http_status, status, resp}}
      {:error, _} = e ->
        e
    end
  end

  @impl true
  def run_status(config, run_id) do
    http = fetch_http!(config)

    case http.(:get, run_url(config, run_id), auth_headers(config), nil) do
      {:ok, 200, %{"status" => status}} -> {:ok, normalize_status(status)}
      {:ok, 200, _resp} -> {:ok, :unknown}
      {:ok, status, resp} -> {:error, {:http_status, status, resp}}
      {:error, _} = e -> e
    end
  end

  @impl true
  def run_conclusion(config, run_id) do
    http = fetch_http!(config)

    case http.(:get, run_url(config, run_id), auth_headers(config), nil) do
      {:ok, 200, %{"conclusion" => conclusion}} -> {:ok, parse_conclusion(conclusion)}
      {:ok, 200, _resp} -> {:error, :not_concluded}
      {:ok, status, resp} -> {:error, {:http_status, status, resp}}
      {:error, _} = e -> e
    end
  end

  @impl true
  def cancel_run(config, run_id) do
    http = fetch_http!(config)

    case http.(:post, run_url(config, run_id) <> "/cancel", auth_headers(config), nil) do
      {:ok, status, _resp} when status in [200, 202, 204] -> :ok
      {:ok, status, resp} -> {:error, {:http_status, status, resp}}
      {:error, _} = e -> e
    end
  end

  # --- helpers ------------------------------------------------------------

  defp find_latest_run_id(config) do
    http = fetch_http!(config)
    url = "#{config.api_base}/repos/#{config.owner}/#{config.repo}/actions/runs?per_page=1"

    case http.(:get, url, auth_headers(config), nil) do
      {:ok, 200, %{"workflow_runs" => [%{"id" => id} | _]}} -> {:ok, id}
      {:ok, 200, _resp} -> {:error, :no_run_found}
      {:ok, status, resp} -> {:error, {:http_status, status, resp}}
      {:error, _} = e -> e
    end
  end

  defp dispatch_url(config) do
    "#{config.api_base}/repos/#{config.owner}/#{config.repo}/actions/workflows/" <>
      "#{config.workflow}/dispatches"
  end

  defp run_url(config, run_id) do
    "#{config.api_base}/repos/#{config.owner}/#{config.repo}/actions/runs/#{run_id}"
  end

  defp auth_headers(config) do
    [
      {"authorization", "Bearer #{config.token}"},
      {"accept", "application/vnd.github+json"}
    ]
  end

  defp fetch_http!(config) do
    Map.get(config, :http) ||
      raise ArgumentError, "CI.GitHubActions requires an injectable :http function"
  end

  defp normalize_status("completed"), do: :done
  defp normalize_status("in_progress"), do: :running
  defp normalize_status("queued"), do: :pending
  defp normalize_status(_), do: :pending

  defp parse_conclusion("success"), do: {"success", 0}
  defp parse_conclusion("failure"), do: {"failure", 1}
  defp parse_conclusion("cancelled"), do: {"cancelled", 2}
  defp parse_conclusion(other), do: {other, 3}

  defp wait_for_correlation_id(config, correlation_id, timeout \\ 30_000) do
    deadline = System.monotonic_time(:millisecond) + timeout
    do_wait_for_correlation_id(config, correlation_id, deadline)
  end

  defp do_wait_for_correlation_id(config, correlation_id, deadline) do
    case find_run_by_correlation(config, correlation_id) do
      {:ok, id} -> {:ok, id}
      :not_found ->
        if System.monotonic_time(:millisecond) < deadline do
          Process.sleep(500)
          do_wait_for_correlation_id(config, correlation_id, deadline)
        else
          {:error, :timeout}
        end
    end
  end

  defp find_run_by_correlation(config, correlation_id) do
    http = fetch_http!(config)
    url = "#{config.api_base}/repos/#{config.owner}/#{config.repo}/actions/runs?per_page=100"

    case http.(:get, url, auth_headers(config), nil) do
      {:ok, 200, %{"workflow_runs" => runs}} ->
        case Enum.find(runs, &match_correlation?(&1, correlation_id)) do
          %{"id" => id} -> {:ok, id}
          nil -> :not_found
        end
      _ ->
        :not_found
    end
  end

  defp match_correlation?(run, correlation_id) do
    case get_in(run, ["inputs", "correlation_id"]) do
      ^correlation_id -> true
      _ -> false
    end
  end
end