defmodule TiannaraOS.Provenance.CertificateIdentity do
  @moduledoc """
  Deterministic certificate-identity derivation boundary (predicate
  P-IDENTITY-CANONICAL, Council-authorized).

  Operationalizes the FROZEN identity contract (fz-b:
  forward_provenance/spec/certificate_identity_spec.yaml, PIN o1) on top of the
  NORMATIVE canonicalization (fz-b reference: tiannara-fp-canon-v1, implemented
  by TiannaraOS.Provenance.Canon). It consumes ONLY the frozen identity input,
  validates it fail-closed, and returns the deterministic SHA-256 identity.

  certificate_id = sha256(canon(%{"candidate_id_spec" => <spec>, "spine" => <spine>}))

  This module is NOT an issuer: deriving an identity never creates, mutates, or
  registers a certificate, has no lifecycle, no revocation, no authority
  activation, and no state. A successful derivation confers no certificate
  validity and no issuance authorization (M7 interpretation 4-5; Section 15 of
  the predicate authorization).

  Scope guard: code in this module may not be extended into issuance, lifecycle,
  revocation, supersession, persistence, or authority service behavior. Any such
  need is an authorization gap and must STOP the gate.
  """

  alias TiannaraOS.Provenance.Canon

  @candidate_id_spec "tiannara-fp-cert-candidate-v1"
  @identity_spec "tiannara-fp-certificate-identity-v1"

  # Frozen spine schema (fz-b PIN o1, mirroring certificate_authority_bridge.ex
  # candidate_spine at lib/certificate_authority_bridge.ex:262-279). All keys are
  # required; value is any canon-renderable term.
  @required_string_keys ~w(candidate_spec source_id contract_id execution_id attempt status result_id result_payload_hash definition_id metric_id corpus_sha256 lineage_id bundle_id)
  @required_boolean_key "certifiable_terminal"
  @required_value_key "value"
  @required_context_key "authority_context"

  @doc "Normative identity of this predicate's contract."
  def spec do
    %{
      "identity_spec" => @identity_spec,
      "candidate_id_spec" => @candidate_id_spec,
      "canon" => "tiannara-fp-canon-v1",
      "formula" => "sha256(canon(%{candidate_id_spec, spine}))",
      "determinism" => "replay-identical for identical canonical inputs",
      "seed_material" => "none (no uuid/timestamp/nonce/process/local identifiers)",
      "certificate_creation" => "never"
    }
  end

  @doc """
  Derive the SHA-256 certificate identity for a frozen identity input.

  Returns {:ok, certificate_id} only when both inputs are complete, well-typed,
  and free of injected identity material. Any deviation fails closed with a typed
  reason and produces NO certificate identity.
  """
  def derive(candidate_id_spec, spine) do
    with :ok <- validate_candidate_id_spec(candidate_id_spec),
         :ok <- validate_spine(spine) do
      {:ok, Canon.sha256(%{"candidate_id_spec" => candidate_id_spec, "spine" => spine})}
    end
  end

  @doc "Canonical bytes for the identity input (byte-parity verification support)."
  def canonical_bytes(candidate_id_spec, spine) do
    %{"candidate_id_spec" => candidate_id_spec, "spine" => spine}
    |> Canon.canon()
  end

  @doc "Full fail-closed validation; returns :ok or {:error, reason}."
  def validate(candidate_id_spec, spine) do
    with :ok <- validate_candidate_id_spec(candidate_id_spec),
         :ok <- validate_spine(spine) do
      :ok
    end
  end

  defp validate_candidate_id_spec(nil), do: {:error, :missing_candidate_id_spec}

  defp validate_candidate_id_spec(spec) when is_binary(spec) and spec == @candidate_id_spec,
    do: :ok

  defp validate_candidate_id_spec(spec) when is_binary(spec),
    do: {:error, {:malformed_candidate_id_spec, spec}}

  defp validate_candidate_id_spec(_), do: {:error, :malformed_candidate_id_spec}

  defp validate_spine(nil), do: {:error, :missing_spine}
  defp validate_spine(spine) when not is_map(spine), do: {:error, :malformed_spine}

  defp validate_spine(spine) do
    with :ok <- check_required_string_keys(spine),
         :ok <- check_boolean_key(spine),
         :ok <- check_value_key(spine),
         :ok <- check_context_key(spine),
         :ok <- check_no_injected_identity_material(spine) do
      :ok
    end
  end

  defp check_required_string_keys(spine) do
    Enum.reduce_while(@required_string_keys, :ok, fn key, :ok ->
      case Map.fetch(spine, key) do
        {:ok, value} when is_binary(value) -> {:cont, :ok}
        {:ok, _} -> {:halt, {:error, {:invalid_type, key}}}
        :error -> {:halt, {:error, {:missing_field, key}}}
      end
    end)
  end

  defp check_boolean_key(spine) do
    case Map.fetch(spine, @required_boolean_key) do
      {:ok, value} when is_boolean(value) -> :ok
      {:ok, _} -> {:error, {:invalid_type, @required_boolean_key}}
      :error -> {:error, {:missing_field, @required_boolean_key}}
    end
  end

  defp check_value_key(spine) do
    case Map.fetch(spine, @required_value_key) do
      {:ok, value} ->
        if canon_renderable?(value) do
          :ok
        else
          {:error, {:non_canonical_value, @required_value_key}}
        end

      :error ->
        {:error, {:missing_field, @required_value_key}}
    end
  end

  defp check_context_key(spine) do
    case Map.fetch(spine, @required_context_key) do
      {:ok, value} when is_map(value) -> :ok
      {:ok, _} -> {:error, {:invalid_type, @required_context_key}}
      :error -> {:error, {:missing_field, @required_context_key}}
    end
  end

  defp check_no_injected_identity_material(spine) do
    case Enum.reject(spine, fn {k, _} ->
           k in (@required_string_keys ++
                   [@required_boolean_key, @required_value_key, @required_context_key])
         end) do
      [] -> :ok
      extras -> {:error, {:unexpected_identity_material, Enum.map(extras, fn {k, _} -> k end)}}
    end
  end

  defp canon_renderable?(nil), do: true
  defp canon_renderable?(b) when is_boolean(b), do: true
  defp canon_renderable?(i) when is_integer(i), do: true
  defp canon_renderable?(f) when is_float(f), do: finite?(f)
  defp canon_renderable?(s) when is_binary(s), do: true
  defp canon_renderable?(l) when is_list(l), do: Enum.all?(l, &canon_renderable?/1)

  defp canon_renderable?(t) when is_tuple(t),
    do: t |> Tuple.to_list() |> Enum.all?(&canon_renderable?/1)

  defp canon_renderable?(m) when is_map(m),
    do: Enum.all?(m, fn {k, v} -> is_binary(k) and canon_renderable?(v) end)

  defp canon_renderable?(_), do: false

  defp finite?(f), do: abs(f) <= 1.7976931348623157e308 or not (f != f)
end
