defmodule Tiannara.CI.GitHubActionsTest do
  use ExUnit.Case, async: true

  alias Tiannara.CI.{GitHubActions, Client}

  @moduletag :ci_provider

  defp mock_http do
    # The provider dispatches with a fresh correlation_id per call; the mock
    # echoes it back on the runs list so the correlation match succeeds.
    {:ok, agent} = Agent.start_link(fn -> nil end)

    fn
      :post, _url, _headers, %{inputs: %{correlation_id: cid}} ->
        Agent.update(agent, fn _ -> cid end)
        {:ok, 204, %{}}

      :get, url, _headers, _ ->
        cond do
          String.contains?(url, "/runs?") ->
            {:ok, 200,
             %{"workflow_runs" => [
                %{"id" => 42, "inputs" => %{"correlation_id" => Agent.get(agent, & &1)}}
              ]}}

          String.contains?(url, "/runs/42") ->
            {:ok, 200, %{"status" => "completed", "conclusion" => "success"}}

          true ->
            {:ok, 404, %{}}
        end
    end
  end

  defp config do
    %{api_base: "https://api.github.com", owner: "o", repo: "r",
      workflow: "ci.yml", ref: "main", token: "t", http: mock_http()}
  end

  test "triggers a workflow and resolves the run id" do
    assert {:ok, 42} = GitHubActions.trigger_workflow(config(), %{foo: "bar"})
  end

  test "polls run status and conclusion" do
    assert {:ok, :done} = GitHubActions.run_status(config(), 42)
    assert {:ok, {"success", 0}} = GitHubActions.run_conclusion(config(), 42)
  end

  test "requires an injectable http function" do
    assert_raise ArgumentError, fn ->
      GitHubActions.trigger_workflow(%{api_base: "x", owner: "o", repo: "r",
                                       workflow: "w", ref: "main", token: "t"}, %{})
    end
  end

  test "CI.Client bridges the provider into a Backend.CI client" do
    client = Client.from_provider(GitHubActions, config())

    assert {:ok, workspace} = client.prepare_workspace.("/baseline")
    assert {:ok, workspace} = client.apply_patch.(workspace, %{id: :p1})
    assert {:ok, 42} = client.submit_job.(workspace, :test, %{command: "mix", args: ["test"]})
    assert client.job_status.(42) == :done
    assert {:ok, "success", 0} = client.fetch_result.(42)
    assert client.cleanup.(workspace) == :ok
  end
end