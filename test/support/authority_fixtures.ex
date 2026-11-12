defmodule Tiannara.Test.AuthorityFixtures do
  @moduledoc """
  CP19.20 test fixtures for Council decision authority.

  Positive fixtures always go through the real `Council.decide/3` path. The
  receipt-signing helper exists only to build adversarial fixtures (stale
  policy/issuer/expiry) and is gated by
  `config :tiannara, :allow_test_receipt_signing`; it is not available in
  production configuration.
  """

  alias Tiannara.Council
  alias Tiannara.Council.{DecisionDigest, DecisionReceipt, MachineAuthorization}
  alias Tiannara.Omega.MintRegistry
  alias Tiannara.World.UnifiedWorldModel

  def unique, do: System.unique_integer([:positive, :monotonic])

  def delete_scope(entity_id) do
    %{
      operation: "delete_entity",
      target: %{entity_id: to_string(entity_id)},
      effect_id: nil
    }
  end

  def delete_payload(entity_id, extra \\ %{}) do
    scope = delete_scope(entity_id)

    Map.merge(
      %{
        mutation_type: :delete_entity,
        mutation_spec: %{id: to_string(entity_id)},
        target: scope.target,
        scope: scope,
        context: nil,
        evidence: [%{source: :authority_fixture}],
        actor: :authority_fixture,
        coherent_with_mission: true,
        degradation_handled: true
      },
      extra
    )
  end

  def decide_delete(entity_id, extra \\ %{}) do
    Council.decide(:delete_entity, delete_payload(entity_id, extra), nil)
  end

  def mint_delete_grant(entity_id, opts \\ []) do
    case decide_delete(entity_id) do
      {:ok, decision, %DecisionReceipt{} = receipt} ->
        MachineAuthorization.mint(decision, receipt,
          decision_type: :delete_entity,
          scope: delete_scope(entity_id),
          ttl: Keyword.get(opts, :ttl, 3600)
        )

      other ->
        other
    end
  end

  def mint_bound_delete!(entity_id, opts \\ []) do
    {:ok, grant} = mint_delete_grant(entity_id, opts)

    {:ok, bound} =
      MachineAuthorization.bind_effect(grant, UnifiedWorldModel.effect_descriptor(entity_id))

    bound
  end

  @doc """
  Signs and records a receipt for adversarial fixtures. Callers choose invalid
  field values (stale policy, wrong issuer, past expiry) deliberately.
  """
  def issue_test_receipt(decision, scope, overrides \\ %{}) do
    now = DateTime.utc_now()

    base = %DecisionReceipt{
      receipt_id: "dcr_test_#{unique()}_#{random_hex(8)}",
      decision_digest: DecisionDigest.decision(decision),
      decision_type: Map.get(overrides, :decision_type, :delete_entity),
      scope_digest: DecisionDigest.scope_digest(scope),
      actor: :authority_fixture,
      issued_at: now,
      expires_at: DateTime.add(now, 300, :second),
      nonce: random_hex(32),
      issuer: DecisionReceipt.issuer(),
      policy_version: Council.policy_version(),
      constitution_version: Council.constitution_version(),
      mac: ""
    }

    receipt = struct(DecisionReceipt, Map.merge(Map.from_struct(base), overrides))
    {:ok, signed} = DecisionReceipt.sign_test(receipt)
    :ok = MintRegistry.record_receipt(signed)
    signed
  end

  @doc "A structurally valid but MAC-forged receipt; never registered."
  def forged_receipt(decision, scope, overrides \\ %{}) do
    receipt = issue_test_receipt(decision, scope, overrides)
    %DecisionReceipt{receipt | mac: String.duplicate("0", 64)}
  end

  def random_hex(bytes), do: :crypto.strong_rand_bytes(bytes) |> Base.encode16(case: :lower)
end

defmodule Tiannara.Test.RegistryFixtures do
  @moduledoc """
  Raw registry-file helpers for integrity/restart tests. They sign records
  with the test registry key so tests can distinguish a MAC failure from a
  semantic (sequence/receipt/grant) failure.
  """

  @format_tag :tiannara_mint_registry
  @format_version 2

  def encode_record(seq, event) do
    key = Application.fetch_env!(:tiannara, :mint_registry_integrity_key)

    mac =
      :crypto.mac(
        :hmac,
        :sha256,
        key,
        :erlang.term_to_binary({@format_tag, @format_version, seq, event}, [:deterministic])
      )
      |> Base.encode16(case: :lower)

    term = :erlang.term_to_binary({@format_tag, @format_version, seq, event, mac})
    [<<byte_size(term)::32>>, term] |> IO.iodata_to_binary()
  end

  def append_raw(path, binary) do
    File.write!(path, binary, [:append])
  end

  def truncate_tail(path, bytes) when is_integer(bytes) and bytes > 0 do
    content = File.read!(path)
    keep = max(byte_size(content) - bytes, 0)
    <<prefix::binary-size(keep), _rest::binary>> = content
    File.write!(path, prefix)
  end

  def snapshot(path) do
    case File.read(path) do
      {:ok, content} -> content
      {:error, :enoent} -> nil
    end
  end

  def restore(path, nil), do: File.rm(path)
  def restore(path, content), do: File.write!(path, content)
end
