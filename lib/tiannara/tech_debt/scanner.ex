defmodule Tiannara.TechDebt.Scanner do
  @moduledoc """
  Lightweight static scanner that flags common tech-debt indicators in source
  text (TODO / FIXME / HACK / XXX / @deprecated) with line locations.

  Constitutional basis: Continuous Self-Evaluation, Observability, Testability.
  """

  alias Tiannara.TechDebt.Item

  @indicators %{
    "TODO" => :todo,
    "FIXME" => :fixme,
    "HACK" => :hack,
    "XXX" => :xxx,
    "@deprecated" => :deprecated
  }

  def scan(source, location \\ "unknown") when is_binary(source) do
    source
    |> String.split("\n")
    |> Enum.with_index(1)
    |> Enum.flat_map(fn {line, line_no} ->
      Enum.flat_map(@indicators, fn {marker, category} ->
        if String.contains?(line, marker) do
          [
            %Item{
              id: :"debt-#{hash({location, line_no, marker})}",
              category: category,
              description: String.trim(line),
              severity: severity_for(category),
              location: "#{location}:#{line_no}",
              effort: :unknown
            }
          ]
        else
          []
        end
      end)
    end)
  end

  defp severity_for(:fixme), do: :high
  defp severity_for(:hack), do: :high
  defp severity_for(:todo), do: :medium
  defp severity_for(:xxx), do: :medium
  defp severity_for(:deprecated), do: :medium

  defp hash(term) do
    term
    |> :erlang.term_to_binary()
    |> then(&:crypto.hash(:sha256, &1))
    |> Base.encode16(case: :lower)
    |> String.slice(0, 8)
  end
end