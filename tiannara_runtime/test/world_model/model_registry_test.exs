defmodule TiannaraRuntime.WorldModel.ModelRegistryTest do
  use ExUnit.Case, async: false

  alias TiannaraRuntime.WorldModel.ModelRegistry

  setup do
    ModelRegistry.reset_table()
    :ok
  end

  defp make_model(overrides \\ []) do
    id = Keyword.get(overrides, :model_id, "wm_test")
    %{
      model_id: id,
      version: Keyword.get(overrides, :version),
      name: Keyword.get(overrides, :name, "Test Model"),
      domain: Keyword.get(overrides, :domain, :physics),
      status: Keyword.get(overrides, :status, :draft),
      fingerprint: Keyword.get(overrides, :fingerprint, "fp_abc123"),
      variables: Keyword.get(overrides, :variables, []),
      parameters: [],
      equations: nil,
      causal_graph: nil,
      observation_model: nil,
      constraints: [],
      metadata: %{},
      evidence_roots: [],
      certificate: nil,
      created_at: DateTime.utc_now() |> DateTime.to_iso8601()
    }
  end

  describe "store_model/2" do
    test "stores a new model with auto-incremented version" do
      model = make_model(version: nil)
      {:ok, stored} = ModelRegistry.store_model(model)
      assert stored.version == 1
      assert stored.model_id == "wm_test"
      assert stored.status == :draft
    end

    test "stores with explicit version" do
      model = make_model(version: 5)
      {:ok, stored} = ModelRegistry.store_model(model)
      assert stored.version == 5
    end

    test "auto-increments version for same model_id" do
      ModelRegistry.store_model(make_model(version: nil))
      ModelRegistry.store_model(make_model(version: nil))
      {:ok, stored} = ModelRegistry.store_model(make_model(version: nil))
      assert stored.version == 3
    end

    test "rejects duplicate version without force" do
      ModelRegistry.store_model(make_model(version: 1))
      assert {:error, msg} = ModelRegistry.store_model(make_model(version: 1))
      assert String.contains?(msg, "already exists")
    end

    test "rejects nil model_id" do
      model = make_model(model_id: nil)
      assert {:error, "model_id is required"} = ModelRegistry.store_model(model)
    end
  end

  describe "get_model/2" do
    test "retrieves a stored model by version" do
      ModelRegistry.store_model(make_model(version: 1))
      {:ok, retrieved} = ModelRegistry.get_model("wm_test", 1)
      assert retrieved.name == "Test Model"
    end

    test "returns not_found for missing model" do
      assert {:error, :not_found} = ModelRegistry.get_model("nonexistent", 1)
    end

    test "returns not_found for wrong version" do
      ModelRegistry.store_model(make_model(version: 1))
      assert {:error, :not_found} = ModelRegistry.get_model("wm_test", 99)
    end
  end

  describe "get_latest_model/1" do
    test "returns the highest version" do
      ModelRegistry.store_model(make_model(version: 1))
      ModelRegistry.store_model(make_model(version: 2, name: "v2"))
      ModelRegistry.store_model(make_model(version: 3, name: "v3"))
      {:ok, latest} = ModelRegistry.get_latest_model("wm_test")
      assert latest.version == 3
      assert latest.name == "v3"
    end

    test "returns not_found for missing model_id" do
      assert {:error, :not_found} = ModelRegistry.get_latest_model("nonexistent")
    end
  end

  describe "list_models/1" do
    test "lists all models" do
      ModelRegistry.store_model(make_model(model_id: "a", version: 1))
      ModelRegistry.store_model(make_model(model_id: "b", version: 1))
      {:ok, models} = ModelRegistry.list_models()
      assert length(models) == 2
    end

    test "filters by domain" do
      ModelRegistry.store_model(make_model(model_id: "a", domain: :physics, version: 1))
      ModelRegistry.store_model(make_model(model_id: "b", domain: :economics, version: 1))
      {:ok, models} = ModelRegistry.list_models(domain: :physics)
      assert length(models) == 1
      assert hd(models).model_id == "a"
    end

    test "filters by status" do
      ModelRegistry.store_model(make_model(model_id: "a", status: :draft, version: 1))
      ModelRegistry.store_model(make_model(model_id: "b", status: :validated, version: 1))
      {:ok, models} = ModelRegistry.list_models(status: :draft)
      assert length(models) == 1
    end

    test "filters by name substring" do
      ModelRegistry.store_model(make_model(model_id: "a", name: "Alpha Model", version: 1))
      ModelRegistry.store_model(make_model(model_id: "b", name: "Beta Model", version: 1))
      {:ok, models} = ModelRegistry.list_models(name: "alpha")
      assert length(models) == 1
    end
  end

  describe "list_versions/1" do
    test "returns all versions in descending order" do
      ModelRegistry.store_model(make_model(version: 1))
      ModelRegistry.store_model(make_model(version: 2))
      ModelRegistry.store_model(make_model(version: 3))
      {:ok, versions} = ModelRegistry.list_versions("wm_test")
      assert Enum.map(versions, & &1.version) == [3, 2, 1]
    end

    test "returns empty list for nonexistent model" do
      {:ok, versions} = ModelRegistry.list_versions("nonexistent")
      assert versions == []
    end
  end

  describe "update_model/3" do
    test "partially updates a model" do
      ModelRegistry.store_model(make_model(version: 1))
      {:ok, updated} = ModelRegistry.update_model("wm_test", 1, name: "Updated Name", status: :validated)
      assert updated.name == "Updated Name"
      assert updated.status == :validated
    end

    test "returns error for nonexistent model" do
      assert {:error, :not_found} = ModelRegistry.update_model("nonexistent", 1, name: "x")
    end
  end

  describe "transition_status/3" do
    test "draft -> validated" do
      ModelRegistry.store_model(make_model(version: 1))
      {:ok, updated} = ModelRegistry.transition_status("wm_test", 1, :validated)
      assert updated.status == :validated
    end

    test "validated -> operational" do
      ModelRegistry.store_model(make_model(version: 1))
      ModelRegistry.transition_status("wm_test", 1, :validated)
      {:ok, updated} = ModelRegistry.transition_status("wm_test", 1, :operational)
      assert updated.status == :operational
    end

    test "rejects invalid transition: draft -> operational" do
      ModelRegistry.store_model(make_model(version: 1))
      assert {:error, msg} = ModelRegistry.transition_status("wm_test", 1, :operational)
      assert String.contains?(msg, "invalid transition")
    end

    test "rejects invalid transition: validated -> draft" do
      ModelRegistry.store_model(make_model(version: 1))
      ModelRegistry.transition_status("wm_test", 1, :validated)
      assert {:error, msg} = ModelRegistry.transition_status("wm_test", 1, :draft)
      assert String.contains?(msg, "invalid transition")
    end

    test "any status can transition to archived" do
      ModelRegistry.store_model(make_model(version: 1))
      {:ok, archived} = ModelRegistry.transition_status("wm_test", 1, :archived)
      assert archived.status == :archived
    end

    test "deprecated -> draft (re-open)" do
      ModelRegistry.store_model(make_model(version: 1))
      ModelRegistry.transition_status("wm_test", 1, :validated)
      ModelRegistry.transition_status("wm_test", 1, :operational)
      ModelRegistry.transition_status("wm_test", 1, :deprecated)
      {:ok, reopened} = ModelRegistry.transition_status("wm_test", 1, :draft)
      assert reopened.status == :draft
    end

    test "archived cannot transition" do
      ModelRegistry.store_model(make_model(version: 1))
      ModelRegistry.transition_status("wm_test", 1, :archived)
      assert {:error, _} = ModelRegistry.transition_status("wm_test", 1, :draft)
    end
  end

  describe "delete_model/2" do
    test "soft-deletes by archiving" do
      ModelRegistry.store_model(make_model(version: 1))
      {:ok, deleted} = ModelRegistry.delete_model("wm_test", 1)
      assert deleted.status == :archived
    end
  end

  describe "model_exists?/1" do
    test "returns true when model exists" do
      ModelRegistry.store_model(make_model(version: 1))
      assert ModelRegistry.model_exists?("wm_test") == true
    end

    test "returns false when model does not exist" do
      assert ModelRegistry.model_exists?("nonexistent") == false
    end
  end

  describe "count_models/0" do
    test "counts all stored versions" do
      assert ModelRegistry.count_models() == 0
      ModelRegistry.store_model(make_model(version: 1))
      assert ModelRegistry.count_models() == 1
      ModelRegistry.store_model(make_model(version: 2))
      assert ModelRegistry.count_models() == 2
    end
  end

  describe "get_model_by_fingerprint/1" do
    test "finds model by fingerprint" do
      ModelRegistry.store_model(make_model(fingerprint: "fp_unique", version: 1))
      {:ok, found} = ModelRegistry.get_model_by_fingerprint("fp_unique")
      assert found.model_id == "wm_test"
    end

    test "returns not_found for unknown fingerprint" do
      assert {:error, :not_found} = ModelRegistry.get_model_by_fingerprint("fp_unknown")
    end
  end

  describe "transfer_model/3" do
    test "forks a model with new id and version 1" do
      ModelRegistry.store_model(make_model(version: 1, name: "Original"))
      {:ok, forked} = ModelRegistry.transfer_model("wm_test", 1, new_model_id: "wm_fork")
      assert forked.model_id == "wm_fork"
      assert forked.version == 1
      assert forked.status == :draft
      assert forked.name == "Original"
    end

    test "original model is unchanged" do
      ModelRegistry.store_model(make_model(version: 1))
      ModelRegistry.transfer_model("wm_test", 1, new_model_id: "wm_fork")
      {:ok, original} = ModelRegistry.get_model("wm_test", 1)
      assert original.status == :draft
    end
  end

  describe "concurrent access" do
    test "multiple processes can read/write simultaneously" do
      tasks =
        for i <- 1..10 do
          Task.async(fn ->
            model = make_model(model_id: "concurrent_#{i}", version: nil)
            ModelRegistry.store_model(model)
          end)
        end

      results = Task.await_many(tasks, 5000)
      assert Enum.all?(results, fn {:ok, stored} -> stored.version == 1 end)

      {:ok, models} = ModelRegistry.list_models()
      assert length(models) == 10
    end
  end
end
