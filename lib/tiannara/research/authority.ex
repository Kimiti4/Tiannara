defmodule Tiannara.Research.Authority do
  @moduledoc """
  Constitutional capability assertion for the Research Director.

  Research planning may create hypotheses and experiment plans, but the
  Director must not expose a direct experiment execution authority.
  """

  def assert_no_execution_authority!(module) when is_atom(module) do
    if function_exported?(module, :execute_experiment, 1) or
         function_exported?(module, :execute_experiment, 2) or
         function_exported?(module, :execute, 1) or
         function_exported?(module, :execute, 2) do
      raise ArgumentError, "Research Director exposes execution authority"
    end

    :ok
  end

  def assert_no_execution_authority!(_), do: raise(ArgumentError, "invalid Research Director reference")
end
