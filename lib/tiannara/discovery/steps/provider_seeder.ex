defmodule Tiannara.Discovery.Steps.ProviderSeeder do
  @moduledoc """
  Registers the real step modules as CapabilityGraph providers so
  `CapabilityGraph.find_optimal_provider/1` resolves them — closing the
  unguarded `:noproc` dispatch path in the WorkflowEngine at the same time.

  The graph model is: a capability vertex + a `:provides` edge from a
  subsystem vertex to it. `find_optimal_provider/1` then returns
  `{:ok, subsystem_id, score}`; this module's `provider_module/1` maps the
  capability back to the real step module, and the contract test asserts the
  OBSERVABLE pair — resolution succeeds AND the provider maps to the real
  module (rules.md: "Verification First"; "Truth has priority over
  confidence").

  Boot-safe: every call is guarded; a missing graph or a failed registration
  logs and degrades instead of crashing the boot (rules.md: "Recover
  gracefully"; "Capability must never outpace verification"). Called from
  DiscoveryScheduler.init, which ControlCenter boots AFTER CapabilityGraph.
  """

  require Logger

  alias Tiannara.Discovery.Steps.{ExperimentStep, ValidationStep}

  @subsystem :discovery_steps

  @providers [
    {:observation_comparison, ExperimentStep},
    {:evidence_validation, ValidationStep}
  ]

  def providers, do: @providers
  def subsystem, do: @subsystem

  @doc "Maps a capability to the real step module that provides it."
  def provider_module(capability) do
    case List.keyfind(@providers, capability, 0) do
      {_, module} -> module
      nil -> nil
    end
  end

  @doc """
  Registers all providers. Returns `:ok` when every capability resolves,
  `{:partial, errors}` when some registration failed (a down graph degrades,
  never crashes).
  """
  def register do
    cg = Tiannara.CEL.Services.CapabilityGraph

    cond do
      not Code.ensure_loaded?(cg) or Process.whereis(cg) == nil ->
        Logger.warning("ProviderSeeder: CapabilityGraph not running — providers unregistered")
        {:error, :capability_graph_unavailable}

      true ->
        results = Enum.map(@providers, &register_one(cg, &1))

        case Enum.filter(results, &match?({:error, _}, &1)) do
          [] -> :ok
          errs -> {:partial, errs}
        end
    end
  rescue
    e ->
      Logger.error("ProviderSeeder: register raised #{inspect(e)}")
      {:error, :register_failed}
  end

  defp register_one(cg, {capability, module}) do
    with :ok <- ensure_capability(cg, capability, module),
         :ok <- ensure_provider_edge(cg, capability) do
      :ok
    else
      {:error, reason} ->
        Logger.warning(
          "ProviderSeeder: #{capability} not registered (#{inspect(reason)}) — " <>
            "contract test will fail until registration works"
        )

        {:error, reason}
    end
  end

  defp ensure_capability(cg, capability, module) do
    case cg.register_capability(capability, %{
           provider_module: module,
           registered_by: __MODULE__,
           registered_at: DateTime.utc_now()
         }) do
      {:ok, ^capability} -> :ok
      {:error, :already_registered} -> :ok
      {:error, reason} -> {:error, reason}
    end
  end

  defp ensure_provider_edge(cg, capability) do
    case cg.declare_provides(@subsystem, capability) do
      :ok -> :ok
      {:error, reason} -> {:error, reason}
    end
  end
end
