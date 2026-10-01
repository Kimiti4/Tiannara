defmodule Tiannara.CEL.Delegation do
  @moduledoc """
  Single governed ingress for consequential ASC and ToolForge delegation.

  CEL selects capabilities; C14/Council remains the authorization authority.
  This module never treats a planned/build artifact as executed.
  """

  alias Tiannara.Council.Authorization

  def delegate(:asc, :process_discovery, discovery) do
    authorize_and_call(:asc, :process_discovery, fn ->
      Tiannara.ASC.Orchestrator.process_discovery(discovery)
    end)
  end

  def delegate(:tool_forge, :engineer, need) do
    authorize_and_call(:tool_forge, :engineer, fn ->
      Tiannara.ToolForge.ToolForgeEngine.engineer_tool(need)
    end)
  end

  def delegate(:tool_forge, :detect_and_engineer, system_state) do
    authorize_and_call(:tool_forge, :detect_and_engineer, fn ->
      Tiannara.ToolForge.ToolForgeEngine.detect_and_engineer(system_state)
    end)
  end

  defp authorize_and_call(capability, action, fun) do
    case Tiannara.Council.authorize(:capability_delegation, %{capability: capability, action: action}) do
      %Authorization{decision: decision} when decision in [:approved, :conditional] ->
        result = fun.()
        {:ok, %{capability: capability, action: action, result: result, governed: true}}
      %Authorization{explanation: explanation} ->
        {:error, {:council_denied, explanation}}
      other ->
        {:error, {:authorization_unavailable, other}}
    end
  rescue
    error -> {:error, {:delegation_failed, error}}
  end
end
