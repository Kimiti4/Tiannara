defmodule TiannaraRuntime.AutonomousResearch.ObservationTest do
  use ExUnit.Case, async: false

  alias TiannaraRuntime.AutonomousResearch.{Observation, ObservationID}

  test "Observation.new validates non-empty origin and payload" do
    assert {:ok, %Observation{}} = Observation.new(%{"source" => "x"}, %{"a" => 1})
    assert {:error, _} = Observation.new(%{}, %{"a" => 1})
    assert {:error, _} = Observation.new(%{"source" => "x"}, %{})
  end

  test "Observation.id is deterministic for semantically identical maps" do
    # Map key order should not matter.
    obs1 = %Observation{
      origin: %{"source" => "sensor", "unit" => "m"},
      payload: %{"value" => 1.23, "var" => "temp"},
      captured_at: "2026-01-01T00:00:00Z",
      metadata: %{"run" => 7}
    }

    obs2 = %Observation{
      origin: %{"unit" => "m", "source" => "sensor"},
      payload: %{"var" => "temp", "value" => 1.23},
      captured_at: "2026-01-01T00:00:00Z",
      metadata: %{"run" => 7}
    }

    assert Observation.id(obs1) == Observation.id(obs2)
    assert is_binary(Observation.id(obs1))
    assert byte_size(Observation.id(obs1)) == 64 # sha256 hex
  end

  test "Observation.serialize_json is deterministic and stable" do
    obs = %Observation{
      origin: %{"source" => "sensor"},
      payload: %{"value" => 2},
      captured_at: "2026-01-01T00:00:00Z",
      metadata: %{"run" => 1}
    }

    s1 = Observation.serialize_json(obs)
    s2 = Observation.serialize_json(obs)

    assert s1 == s2
    assert byte_size(s1) > 0
  end

  test "Observation.id matches hash of canonical JSON bytes (via ObservationID.from_bytes)" do
    obs = %Observation{
      origin: %{"source" => "sensor"},
      payload: %{"value" => 2},
      captured_at: "2026-01-01T00:00:00Z",
      metadata: %{"run" => 1}
    }

    canonical_bytes = Observation.serialize_json(obs)
    expected = ObservationID.from_bytes(canonical_bytes)

    assert Observation.id(obs) == expected
  end
end
