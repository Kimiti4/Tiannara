defmodule Tiannara.Domains.CanonicalRegistryTest do
  @moduledoc """
  AC-001-A: Canonical registry tests.

  Verifies:
  - 20 canonical domains present
  - :science, :mathematics, :cs excluded
  - API contract coherent
  - ComputerScience merged into :computation
  """

  use ExUnit.Case, async: false

  alias Tiannara.Domains.CanonicalRegistry

  @canonical_domains [
    :engineering,
    :physics,
    :chemistry,
    :medicine,
    :cybernetics,
    :governance,
    :computation,
    :agriculture,
    :energy,
    :logistics,
    :cognition,
    :materials,
    :robotics,
    :economics,
    :philosophy,
    :sociology,
    :linguistics,
    :aerospace,
    :ecology,
    :architecture
  ]

  # Registry is started by the application supervision tree (AC-001-B).
  # No start_supervised! needed — the global instance is used directly.

  describe "canonical ontology" do
    test "returns exactly 20 canonical domains" do
      domains = CanonicalRegistry.all()
      assert length(domains) == 20
    end

    test "includes all required domains" do
      domains = CanonicalRegistry.all()

      for domain <- @canonical_domains do
        assert domain in domains, "Missing canonical domain: #{domain}"
      end
    end

    test "excludes :science (methodology, not domain)" do
      domains = CanonicalRegistry.all()
      refute :science in domains
    end

    test "excludes :mathematics (epistemic substrate)" do
      domains = CanonicalRegistry.all()
      refute :mathematics in domains
    end

    test "excludes :logic (epistemic substrate)" do
      domains = CanonicalRegistry.all()
      refute :logic in domains
    end

    test "excludes :cs (merged into :computation)" do
      domains = CanonicalRegistry.all()
      refute :cs in domains
    end

    test "includes :computation (ComputerScience merged here)" do
      domains = CanonicalRegistry.all()
      assert :computation in domains
    end
  end

  describe "get/1" do
    test "returns domain record for valid domain" do
      assert {:ok, record} = CanonicalRegistry.get(:physics)
      assert record.id == :physics
      assert record.module == Tiannara.Domains.Physics
      assert record.lifecycle == :active
      assert is_map(record.metadata)
    end

    test "returns error for invalid domain" do
      assert {:error, :not_found} = CanonicalRegistry.get(:invalid)
    end

    test "returns error for excluded domains" do
      assert {:error, :not_found} = CanonicalRegistry.get(:science)
      assert {:error, :not_found} = CanonicalRegistry.get(:mathematics)
      assert {:error, :not_found} = CanonicalRegistry.get(:cs)
    end
  end

  describe "get_metadata/1" do
    test "returns metadata for valid domain" do
      assert {:ok, metadata} = CanonicalRegistry.get_metadata(:physics)
      assert is_map(metadata)
      assert Map.has_key?(metadata, :name)
      assert Map.has_key?(metadata, :description)
    end

    test "returns error for invalid domain" do
      assert {:error, :not_found} = CanonicalRegistry.get_metadata(:invalid)
    end
  end

  describe "get_module/1" do
    test "returns module binding for valid domain" do
      assert {:ok, module} = CanonicalRegistry.get_module(:physics)
      assert module == Tiannara.Domains.Physics
    end

    test "returns module binding for computation (ComputerScience merged)" do
      assert {:ok, module} = CanonicalRegistry.get_module(:computation)
      assert module == Tiannara.Domains.Computation
    end

    test "returns error for invalid domain" do
      assert {:error, :not_found} = CanonicalRegistry.get_module(:invalid)
    end
  end

  describe "get_lifecycle/1" do
    test "returns lifecycle for valid domain" do
      assert {:ok, lifecycle} = CanonicalRegistry.get_lifecycle(:physics)
      assert lifecycle == :active
    end

    test "returns error for invalid domain" do
      assert {:error, :not_found} = CanonicalRegistry.get_lifecycle(:invalid)
    end
  end

  describe "ontology_version/0" do
    test "returns ontology version" do
      version = CanonicalRegistry.ontology_version()
      assert is_binary(version)
      assert version == "1.0.0"
    end
  end

  describe "domain record structure" do
    test "all domains have required fields" do
      for domain_id <- @canonical_domains do
        assert {:ok, record} = CanonicalRegistry.get(domain_id)
        assert Map.has_key?(record, :id)
        assert Map.has_key?(record, :module)
        assert Map.has_key?(record, :metadata)
        assert Map.has_key?(record, :lifecycle)
        assert record.id == domain_id
      end
    end

    test "all domains have active lifecycle by default" do
      for domain_id <- @canonical_domains do
        assert {:ok, :active} = CanonicalRegistry.get_lifecycle(domain_id)
      end
    end
  end

  describe "all_records/0" do
    test "returns exactly 20 records" do
      records = CanonicalRegistry.all_records()
      assert length(records) == 20
    end

    test "every record has a canonical domain ID" do
      records = CanonicalRegistry.all_records()

      for record <- records do
        assert record.id in @canonical_domains,
               "Non-canonical ID found: #{record.id}"
      end
    end

    test "records correspond exactly to canonical IDs" do
      records = CanonicalRegistry.all_records()
      record_ids = Enum.map(records, & &1.id) |> MapSet.new()
      canonical_ids = MapSet.new(@canonical_domains)

      assert MapSet.equal?(record_ids, canonical_ids),
             "Record IDs do not match canonical ontology"
    end

    test "no :science record exists" do
      records = CanonicalRegistry.all_records()
      refute Enum.any?(records, &(&1.id == :science))
    end

    test "no :mathematics record exists" do
      records = CanonicalRegistry.all_records()
      refute Enum.any?(records, &(&1.id == :mathematics))
    end

    test "no :logic record exists" do
      records = CanonicalRegistry.all_records()
      refute Enum.any?(records, &(&1.id == :logic))
    end

    test "no :cs record exists" do
      records = CanonicalRegistry.all_records()
      refute Enum.any?(records, &(&1.id == :cs))
    end

    test "result is deterministic" do
      result1 = CanonicalRegistry.all_records()
      result2 = CanonicalRegistry.all_records()
      assert result1 == result2
    end

    test "every record has name, description, active_programs, last_research_activity" do
      records = CanonicalRegistry.all_records()

      for record <- records do
        assert Map.has_key?(record, :name)
        assert Map.has_key?(record, :description)
        assert Map.has_key?(record, :active_programs)
        assert Map.has_key?(record, :last_research_activity)
        assert is_binary(record.name)
        assert is_binary(record.description)
        assert is_list(record.active_programs)
      end
    end
  end

  describe "API contract coherence" do
    test "all API functions exist and are callable" do
      assert function_exported?(CanonicalRegistry, :all, 0)
      assert function_exported?(CanonicalRegistry, :all_records, 0)
      assert function_exported?(CanonicalRegistry, :get, 1)
      assert function_exported?(CanonicalRegistry, :get_metadata, 1)
      assert function_exported?(CanonicalRegistry, :get_module, 1)
      assert function_exported?(CanonicalRegistry, :get_lifecycle, 1)
      assert function_exported?(CanonicalRegistry, :ontology_version, 0)
    end

    test "dead APIs are NOT present" do
      refute function_exported?(CanonicalRegistry, :add_program, 2)
      refute function_exported?(CanonicalRegistry, :record_activity, 3)
      refute function_exported?(CanonicalRegistry, :get_all_domain_ids, 0)
      refute function_exported?(CanonicalRegistry, :get_knowledge_capital, 1)
      refute function_exported?(CanonicalRegistry, :get_portfolio_vector, 1)
    end
  end
end
