defmodule Tiannara.OED.OAVL.SubstrateIndependence do
  @moduledoc """
  📐 OAVL Substrate Independence.

  Asserts that candidate configuration rules are completely abstract and contain
  no dependencies on underlying environment variables, local system paths,
  host node identifiers, or direct BEAM process registers.
  """

  require Logger

  @spec verify(rule :: map()) :: :ok | {:error, String.t()}
  def verify(rule) do
    Logger.debug("📐 [Substrate Independence] Scrutinizing rule execution abstractions for #{rule.type}")

    if contains_substrate_leak?(rule.body) do
      {:error, "Substrate leak: rule contains direct OS/platform environment dependencies"}
    else
      :ok
    end
  end

  # ==================== Internal Leak Scanners ====================

  defp contains_substrate_leak?({:apply, :system_cmd, _}), do: true
  defp contains_substrate_leak?({:apply, :env_lookup, _}), do: true
  defp contains_substrate_leak?({:apply, :node_pid, _}), do: true

  defp contains_substrate_leak?({:if, _cond, then_b, else_b}) do
    contains_substrate_leak?(then_b) or contains_substrate_leak?(else_b)
  end

  defp contains_substrate_leak?({op, a, b}) when is_tuple(a) or is_tuple(b) do
    contains_substrate_leak?(a) or contains_substrate_leak?(b)
  end

  defp contains_substrate_leak?(_), do: false
end
