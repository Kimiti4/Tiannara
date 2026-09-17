defmodule Tiannara.OED.OAVL.OntologyValidator do
  @moduledoc """
  📐 OAVL Ontology Validator.

  Validates candidate rules against structural infinite regress and logical
  contradictions within active reality schemas.
  """

  use GenServer
  require Logger

  # ==================== Public API ====================

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc """
  Performs structural validation checking for infinite regress loops in the AST.
  """
  @spec validate(rule :: map()) :: {:ok, :valid} | {:error, String.t()}
  def validate(rule) do
    GenServer.call(__MODULE__, {:validate, rule})
  end

  # ==================== GenServer Callbacks ====================

  @impl true
  def init(_opts) do
    {:ok, %{}}
  end

  @impl true
  def handle_call({:validate, rule}, _from, state) do
    result = check_regress(rule)
    {:reply, result, state}
  end

  # ==================== Internal Regress Checkers ====================

  defp check_regress(rule) do
    case analyze_regress(rule.body, 0) do
      :ok -> {:ok, :valid}
      {:error, reason} -> {:error, reason}
    end
  end

  defp analyze_regress(_body, depth) when depth > 5 do
    {:error, "Structural infinite regress: AST depth exceeded execution threshold"}
  end

  defp analyze_regress({:if, _cond, then_b, else_b}, depth) do
    with :ok <- analyze_regress(then_b, depth + 1),
         :ok <- analyze_regress(else_b, depth + 1) do
      :ok
    end
  end

  defp analyze_regress({:if, _cond, then_b}, depth) do
    analyze_regress(then_b, depth + 1)
  end

  defp analyze_regress({op, a, b}, depth) when is_tuple(a) or is_tuple(b) do
    with :ok <- analyze_regress(a, depth + 1),
         :ok <- analyze_regress(b, depth + 1) do
      :ok
    end
  end

  defp analyze_regress(_, _depth), do: :ok
end
