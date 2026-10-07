defmodule Tiannara.Sentinel.DiscoveryVerificationRecorderTest do
  use ExUnit.Case, async: false

  alias Tiannara.Sentinel.DiscoveryVerificationGraph
  alias Tiannara.Sentinel.DiscoveryVerificationRecorder

  setup do
    case Process.whereis(DiscoveryVerificationGraph) do
      nil -> {:ok, _pid} = DiscoveryVerificationGraph.start_link([])
      _pid -> :ok
    end

    :ok = DiscoveryVerificationGraph.verify_chain()
    :ok
  end

  test "records discovery, every domain result, and ACL/OAVL evidence through archive" do
    discovery = %{
      id: "discovery-recorder-001",
      domain: :physics,
      assumptions: [:independent_observations]
    }

    verifier = fn evidence ->
      {:ok, %{
        domain: evidence.verification_domain,
        status: :passed,
        independent: true,
        counterevidence: [],
        new_dependencies: []
      }}
    end

    opts = %{
      archive_writer: fn archived -> {:ok, Map.put(archived, :persisted, true)} end,
      acl_validator: fn evidence ->
        assert evidence.evidence_id
        {:ok, %{status: :pass, checked: :acl}}
      end,
      oavl_validator: fn evidence ->
        assert evidence.acl_result
        {:ok, %{status: :pass, checked: :oavl}}
      end
    }

    assert {:ok, result} =
             DiscoveryVerificationRecorder.verify_and_record(
               discovery,
               [:engineering],
               verifier,
               opts
             )

    assert result.verification.all_domains_passed
    assert result.validation.acl_status == :passed
    assert result.validation.oavl_status == :passed
    assert result.discovery.archive.persisted
    assert result.oavl_node.kind == :oavl_audit
    assert result.oavl_node.archive.kind == :oavl_audit
    assert :ok = DiscoveryVerificationGraph.verify_chain()
  end

  test "fails closed when archive persistence is unavailable" do
    discovery = %{id: "discovery-recorder-002", domain: :statistics}

    verifier = fn evidence ->
      {:ok, %{domain: evidence.verification_domain, status: :passed, independent: true}}
    end

    opts = %{
      acl_validator: fn _ -> {:ok, %{status: :pass}} end,
      oavl_validator: fn _ -> {:ok, %{status: :pass}} end
    }

    assert {:error, {:archive_writer, :provider_unavailable}} =
             DiscoveryVerificationRecorder.verify_and_record(discovery, [:statistics], verifier, opts)
  end
end
