defmodule Tiannara.Sentinel.Authority do
  @moduledoc """
  Constitutional capability assertion for Sentinel.

  The Sentinel is observational: this predicate proves that the supplied
  reference does not expose consequential action authority.
  """

  def assert_no_action_authority!(reference) do
    unless observational_reference?(reference) do
      raise ArgumentError, "Sentinel reference exposes action authority"
    end

    :ok
  end

  defp observational_reference?(module) when is_atom(module) do
    not function_exported?(module, :execute, 1) and
      not function_exported?(module, :execute, 2) and
      not function_exported?(module, :deploy, 1) and
      not function_exported?(module, :deploy, 2)
  end

  defp observational_reference?(_), do: false
end
