defmodule TiannaraOS.DiscoveryRegistryPromotionFailClosedTest do
  use ExUnit.Case, async: false

  alias TiannaraOS.DiscoveryRegistry

  test "caller-asserted ACL/OAVL pass statuses cannot authorize operational promotion" do
    path =
      Path.join(
        System.tmp_dir!(),
        "discovery-registry-promotion-#{System.unique_integer([:positive])}.dets"
      )

    {:ok, pid} = DiscoveryRegistry.start_link(file: path)

    on_exit(fn ->
      if Process.alive?(pid), do: GenServer.stop(pid)
      File.rm(path)
    end)

    discovery = %{
      id: "promotion-gate-test",
      name: "promotion gate test",
      domain_id: "governance",
      experiment_ids: ["experiment-1"],
      evidence_ids: ["evidence-1"],
      theory_ids: ["theory-1"]
    }

    assert {:ok, _} = DiscoveryRegistry.register(discovery)

    reproduction_evidence = %{
      evidence_class: :real,
      execution_mode: :real_execution,
      real_observation: true,
      effect_verified: true,
      reproduction_evidence: %{replications: 3, independent_runs: true}
    }

    assert {:ok, reproduced} =
             DiscoveryRegistry.update_validation_status_with_lineage(
               discovery.id,
               :reproduced,
               reproduction_evidence,
               fn archive -> {:ok, archive} end
             )

    operational_assertions = %{
      evidence_class: :real,
      execution_mode: :real_execution,
      real_observation: true,
      effect_verified: true,
      acl_status: :pass,
      oavl_status: :pass,
      acl_artifact: %{status: :pass},
      oavl_artifact: %{status: :pass}
    }

    assert {:error, :trusted_operational_evidence_verification_unavailable} =
             DiscoveryRegistry.update_validation_status_with_lineage(
               reproduced.id,
               :operationally_validated,
               operational_assertions,
               fn archive -> {:ok, archive} end
             )

    assert {:ok, still_reproduced} = DiscoveryRegistry.get(discovery.id)
    assert still_reproduced.validation_status == :reproduced
  end
end
