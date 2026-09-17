defmodule Tiannara.World.CanonicalSchemaPropertiesTest do
  use ExUnit.Case, async: true
  use ExUnitProperties

  alias Tiannara.World.CanonicalWorldState

  describe "Canonical World State schema" do
    property "every valid domain accepts its own entity types" do
      check all domain <- member_of(CanonicalWorldState.domains()) do
        types = CanonicalWorldState.entity_types_for(domain)
        assert is_list(types)
        assert length(types) > 0

        Enum.each(types, fn type ->
          spec = %{
            id: "prop_#{:crypto.strong_rand_bytes(4) |> Base.encode16(case: :lower)}",
            domain: domain, type: type, confidence: 0.5, uncertainty: 0.5,
            provenance: %{origin: :property_test, produced_by: :stream_data, produced_at: DateTime.utc_now()},
            owner_subsystem: :test_suite, version: 1,
            created_at: DateTime.utc_now(), updated_at: DateTime.utc_now(), status: :active
          }
          assert CanonicalWorldState.validate_entity(spec) == :ok
        end)
      end
    end

    property "invalid domains are always rejected" do
      check all bogus <- binary(length: 8) |> map(fn b ->
        try do
          :erlang.binary_to_atom(b, :utf8)
        rescue
          _ -> :bogus_atom
        end
      end) do
        if bogus not in CanonicalWorldState.domains() do
          spec = %{
            id: "x", domain: bogus, type: :fact, confidence: 0.5, uncertainty: 0.5,
            provenance: %{origin: :x, produced_by: :x, produced_at: DateTime.utc_now()}
          }
          assert {:error, _} = CanonicalWorldState.validate_entity(spec)
        end
      end
    end

    property "confidence + uncertainty must sum to ~1.0" do
      check all conf <- float(min: 0.0, max: 1.0),
                unc <- float(min: 0.0, max: 1.0) do
        spec = %{
          id: "sum_test", domain: :knowledge, type: :fact,
          confidence: conf, uncertainty: unc,
          provenance: %{origin: :x, produced_by: :x, produced_at: DateTime.utc_now()},
          owner_subsystem: :test_suite, version: 1,
          created_at: DateTime.utc_now(), updated_at: DateTime.utc_now(), status: :active
        }
        result = CanonicalWorldState.validate_entity(spec)
        if abs(conf + unc - 1.0) <= 0.01 do
          refute match?({:error, :confidence_uncertainty_mismatch}, result)
        else
          assert {:error, :confidence_uncertainty_mismatch} = result
        end
      end
    end

    property "missing provenance fields produce specific errors" do
      check all has_origin <- boolean(),
                has_produced_by <- boolean(),
                has_produced_at <- boolean() do
        prov =
          %{}
          |> then(fn m -> if has_origin, do: Map.put(m, :origin, :x), else: m end)
          |> then(fn m -> if has_produced_by, do: Map.put(m, :produced_by, :x), else: m end)
          |> then(fn m -> if has_produced_at, do: Map.put(m, :produced_at, DateTime.utc_now()), else: m end)

        spec = %{
          id: "prov_test", domain: :knowledge, type: :fact,
          confidence: 0.5, uncertainty: 0.5, provenance: prov,
          owner_subsystem: :test_suite, version: 1,
          created_at: DateTime.utc_now(), updated_at: DateTime.utc_now(), status: :active
        }
        result = CanonicalWorldState.validate_entity(spec)

        cond do
          has_origin and has_produced_by and has_produced_at ->
            refute match?({:error, {:missing_provenance_field, _}}, result)
          not has_origin ->
            assert {:error, {:missing_provenance_field, :origin}} = result
          not has_produced_by ->
            assert {:error, {:missing_provenance_field, :produced_by}} = result
          not has_produced_at ->
            assert {:error, {:missing_provenance_field, :produced_at}} = result
        end
      end
    end
  end
end
