defmodule Tiannara.Domains.ExtruderTest do
  use ExUnit.Case, async: true

  alias Tiannara.Domains.Extruder

  test "dispatches only explicitly implemented domains" do
    assert %{domain: :engineering, status: :success} =
             Extruder.extract_blueprint(:engineering, :synthesis)

    assert %{domain: :medicine, status: :failed, reason: {:unsupported_domain, :medicine}} =
             Extruder.extract_blueprint(:medicine, :synthesis)
  end
end
