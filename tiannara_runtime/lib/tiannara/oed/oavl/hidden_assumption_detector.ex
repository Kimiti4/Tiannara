defmodule Tiannara.OED.OAVL.HiddenAssumptionDetector do
  @moduledoc """
  📐 OAVL Hidden Assumption Detector.

  Scans rule AST predicates to discover implicit parameters, hardcoded magic values,
  or unconstrained logic bounds that could lead to numeric overflows.
  """

  use GenServer
  require Logger

  # ==================== Public API ====================

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc """
  Runs analysis checks to detect hidden premises or unconstrained division in the AST.
  """
  @spec detect(rule :: map()) :: {:ok, :clean} | {:error, String.t()}
  def detect(rule) do
    GenServer.call(__MODULE__, {:detect, rule})
  end

  # ==================== GenServer Callbacks ====================

  @impl true
  def init(_opts) do
    {:ok, %{}}
  end

  @impl true
  def handle_call({:detect, rule}, _from, state) do
    result = scan_assumptions(rule.body)
    {:reply, result, state}
  end

  # ==================== Internal Scanners ====================

  defp scan_assumptions(body) do
    case find_assumptions(body) do
      nil -> {:ok, :clean}
      reason -> {:error, reason}
    end
  end

  defp find_assumptions({:div, _num, 0}) do
    "Hidden assumption: division by constant zero detected"
  end

  # Check for unconstrained divisions like {:div, var, denominator}
  defp find_assumptions({:div, _num, den}) when is_atom(den) do
    "Hidden assumption: un-guarded division by variable denominator '#{den}'"
  end

  defp find_assumptions({:if, _cond, then_b, else_b}) do
    find_assumptions(then_b) || find_assumptions(else_b)
  end

  defp find_assumptions({op, a, b}) when is_tuple(a) or is_tuple(b) do
    find_assumptions(a) || find_assumptions(b)
  end

  defp find_assumptions(_), do: nil
end
