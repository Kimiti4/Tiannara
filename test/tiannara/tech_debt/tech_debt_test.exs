defmodule Tiannara.TechDebt.TechDebtTest do
  use ExUnit.Case, async: true

  alias Tiannara.TechDebt.{Scanner, Registry, Report}

  @moduletag :tech_debt

  defp sample_source do
    """
    defmodule Sample do
      # TODO: refactor this
      def a, do: 1

      # FIXME: handle error
      def b, do: 2

      # HACK: temporary workaround
      def c, do: 3
    end
    """
  end

  test "scanner detects TODO/FIXME/HACK with locations" do
    items = Scanner.scan(sample_source(), "sample.ex")

    categories = Enum.map(items, & &1.category)
    assert :todo in categories
    assert :fixme in categories
    assert :hack in categories

    assert Enum.all?(items, &String.starts_with?(&1.location, "sample.ex:"))
  end

  test "registry prioritizes by severity and resolves items" do
    items = Scanner.scan(sample_source(), "sample.ex")
    registry = Registry.new() |> Registry.add_all(items)

    assert length(Registry.open_items(registry)) == length(items)

    [first | _] = Registry.prioritize(registry)
    assert first.severity in [:high, :critical]

    resolved = Registry.resolve(registry, first.id, "fixed")
    assert length(Registry.open_items(resolved)) == length(items) - 1
  end

  test "report renders a prioritized summary" do
    items = Scanner.scan(sample_source(), "sample.ex")
    registry = Registry.new() |> Registry.add_all(items)
    text = Report.render(registry)

    assert text =~ "TECH-DEBT REPORT"
    assert text =~ "open:"
    assert text =~ "sample.ex"
  end
end