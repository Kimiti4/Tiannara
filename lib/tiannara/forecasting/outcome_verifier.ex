defmodule Tiannara.Forecasting.OutcomeVerifier do
  @moduledoc """
  Independent verification of acquired evidence against a registered forecast.

  The acquisition layer reports *what was retrieved*. This module decides
  *whether that evidence supports the forecast's outcome definition*. The two
  responsibilities are separate, and a self-asserted `verified: true` from an
  acquisition adapter advances nothing.

  ## What this establishes, and what it does not

  | Dimension              | Established here?                                        |
  |------------------------|----------------------------------------------------------|
  | Evidence integrity     | Yes — the stored evidence is re-read and re-digested.     |
  | Source identity        | To the declared policy's level.                           |
  | Transport protection   | Only if the acquisition recorded it.                      |
  | Publisher authenticity | **No** — no publisher signature is verified.             |
  | Semantic verification  | Yes — the evidence is independently parsed and compared.  |
  | Temporal eligibility   | Yes — the registered typed horizon is applied.            |
  | Corroboration          | Only if independent supporting evidence was supplied.      |

  A separate module is not independence by itself. Independence here means the
  verifier reads the **stored evidence**, not the acquisition adapter's parsed
  output, and that it recomputes the digest rather than trusting the recorded
  one.

  ## Statuses

  A verification that *completed* always returns `{:ok, result}` — including a
  negative verdict. A negative verdict is a finding, not an absence of
  findings, and collapsing it into an error tuple would lose the distinction
  the assurance contract exists to preserve.

  | Status                                  | Meaning                                                             |
  |-----------------------------------------|---------------------------------------------------------------------|
  | `:verified`                             | Everything established, including publisher authenticity.           |
  | `:verified_with_limited_source_assurance` | Everything except publisher authenticity, which could not be established. |
  | `:requires_review`                      | Ambiguous, contradictory, or dependent on outside information.      |
  | `:unverified`                           | A required check could not be completed.                            |
  | `:rejected`                             | A check failed outright.                                            |
  | `:unavailable`                          | The evidence or its store could not be reached.                     |

  `:verified_with_limited_source_assurance` is **not** interchangeable with
  `:verified`.

  **`:verified` is currently unreachable.** Publisher authenticity is not
  established by this implementation, so the strongest status it can produce
  is `:verified_with_limited_source_assurance`. That is a statement about the
  system, not a gap in the reporting: the status is reported as the policy
  allows, and the policy that would permit `:verified` is not ratified
  (TCP-B-066).

  ## The verification transition

  `apply/2` is the only sanctioned way for an observation to become
  *verified*. It refuses a verification result that is not bound to the
  observation it is being applied to, and it recomputes the record's digest so
  that a tampered record is detected.

  ## Limitation

  A verification record is **integrity-bound, not authenticated**. Its digest
  detects modification; it does not prove that the verifier process produced
  it. This is the same standing limitation as the durable log's chain
  (TCP-B-058, TCP-B-061). The reproduction path is to re-run `verify/3`
  against the evidence store.
  """
  alias Tiannara.Forecasting.Contracts.{Forecast, Horizon}

  @policy_version "efdi-verification-v1"

  @type status ::
          :verified
          | :verified_with_limited_source_assurance
          | :requires_review
          | :unverified
          | :rejected
          | :unavailable

  @type result :: %{
          required(:forecast_id) => String.t(),
          required(:forecast_digest) => binary(),
          required(:outcome_definition_digest) => binary(),
          required(:horizon_digest) => binary(),
          required(:observation_id) => String.t() | nil,
          required(:observation_digest) => binary(),
          required(:evidence_digest) => binary() | nil,
          required(:source_identity) => String.t() | nil,
          required(:verification_policy_version) => String.t(),
          required(:assurance) => map(),
          required(:status) => status(),
          required(:reason) => atom(),
          required(:verified_at) => DateTime.t(),
          required(:record_digest) => binary()
        }

  @doc "The verification policy version in force."
  @spec policy_version() :: String.t()
  def policy_version, do: @policy_version

  @doc """
  Verifies an observation against its registered forecast.

  `evidence_reader` is called with the observation's `evidence_ref` and must
  return `{:ok, raw_bytes}`. The verifier re-digests those bytes itself.

  Returns `{:ok, result}` for every verification that completed, whatever its
  verdict, and `{:error, :invalid_verification_input}` only when a
  verification could not be attempted at all.
  """
  @spec verify(Forecast.t(), map(), (String.t() -> {:ok, binary()} | {:error, atom()})) ::
          {:ok, result()} | {:error, atom()}
  def verify(%Forecast{} = forecast, observation, evidence_reader) when is_map(observation) do
    if Tiannara.Forecasting.VerificationAuthority.server() |> Process.whereis() |> is_nil() do
      {:error, :verification_authority_unavailable}
    else
      do_verify(forecast, observation, evidence_reader)
    end
  end

  defp do_verify(%Forecast{} = forecast, observation, evidence_reader) do
    case read_evidence(observation, evidence_reader) do
      {:error, {status, reason}} ->
        {:ok, result(forecast, observation, %{evidence_retrieved: :failed}, status, reason)}

      {:ok, raw, read_assurance} ->
        steps = [
          fn -> check_binding(observation, forecast) end,
          fn -> check_digest(observation, raw) end,
          fn -> check_semantics(observation, raw, forecast) end,
          fn -> check_temporal(observation, forecast) end,
          fn -> check_source(observation) end
        ]

        case sequence(steps, read_assurance) do
          {:ok, assurance} ->
            {:ok,
             result(
               forecast,
               observation,
               Map.put(assurance, :publisher_authenticity, :not_established),
               :verified_with_limited_source_assurance,
               :publisher_authenticity_not_established
             )}

          {:error, status, reason, assurance} ->
            {:ok, result(forecast, observation, assurance, status, reason)}
        end
    end
  end

  def verify(_forecast, _observation, _reader), do: {:error, :invalid_verification_input}

  @doc """
  Applies a verification result to the observation it belongs to.

  This is the verification transition. It refuses a result that is not bound
  to the observation — by observation id, evidence digest, forecast id and
  forecast digest — and it recomputes the record's own digest, so a tampered
  record cannot be applied.

  The returned observation carries the verdict even when the verdict is
  negative. A negative verdict makes the observation *ineligible* for
  resolution; it does not make it unreadable.
  """
  @spec apply(result(), map()) :: {:ok, map()} | {:error, atom()}
  def apply(verification, observation) when is_map(verification) and is_map(observation) do
    with :ok <- check_apply_binding(verification, observation),
         :ok <- check_policy(verification),
         :ok <- check_record_digest(verification) do
      {:ok,
       %{
         observation
         | verification_status: verification.status,
           verified_at: verification.verified_at,
           verification_policy_version: verification.verification_policy_version,
           assurance: verification.assurance
       }}
    end
  end

  def apply(_verification, _observation), do: {:error, :invalid_verification_input}

  @doc """
  Recomputes the digest of a verification record.

  Exposed so that a consumer can check a record it did not receive from this
  module.
  """
  @spec record_digest(map()) :: binary()
  def record_digest(verification) when is_map(verification) do
    Tiannara.Forecasting.VerificationAuthority.sign(verification)
  end

  @doc """
  Asks the protected verification authority whether `verification` was
  actually signed by it.

  A public checksum is not proof of provenance. Only the authority's key can
  produce a digest that this function accepts.
  """
  @spec authentic?(map(), atom()) :: :ok | {:error, atom()}
  def authentic?(nil, _name), do: {:error, :verification_record_missing}

  def authentic?(verification, name \\ Tiannara.Forecasting.VerificationAuthority.server())
      when is_map(verification) do
    Tiannara.Forecasting.VerificationAuthority.verify(verification, name)
  end

  # The binding check establishes that the observation is bound to the
  # registered forecast: the forecast id, the forecast digest, the
  # outcome-definition digest and the horizon digest all match. These are
  # security-relevant bindings and are part of the assurance result so that
  # re-execution compares them too.
  defp check_binding(observation, forecast) do
    cond do
      Map.get(observation, :forecast_id) != forecast.id ->
        {:error, {:rejected, :forecast_id_mismatch}}

      Map.get(observation, :forecast_digest) != Forecast.digest(forecast) ->
        {:error, {:rejected, :forecast_digest_mismatch}}

      Map.get(observation, :outcome_definition_digest) != forecast.outcome_definition_digest ->
        {:error, {:rejected, :outcome_definition_digest_mismatch}}

      Map.get(observation, :horizon_digest) != forecast.horizon_digest ->
        {:error, {:rejected, :horizon_digest_mismatch}}

      true ->
        {:ok, %{binding: :established}}
    end
  end

  # ------------------------------------------------------------- steps

  defp read_evidence(observation, reader) do
    ref = Map.get(observation, :evidence_ref)

    if not is_binary(ref) do
      {:error, {:unverified, :evidence_reference_missing}}
    else
      case safe_read(reader, ref) do
        {:ok, raw} when is_binary(raw) -> {:ok, raw, %{evidence_retrieved: :established}}
        {:ok, _other} -> {:error, {:unavailable, :evidence_read_failed}}
        {:error, reason} -> {:error, {:unavailable, reason}}
      end
    end
  end

  defp safe_read(reader, ref) do
    reader.(ref)
  rescue
    _ -> {:error, :evidence_read_failed}
  catch
    :exit, _reason -> {:error, :evidence_read_failed}
  end

  # Runs the remaining checks in order, accumulating the assurance that each
  # one established. The first failure stops the sequence, and the assurance
  # established up to that point is preserved in the result.
  defp sequence(steps, acc) do
    Enum.reduce_while(steps, {:ok, acc}, fn step, {:ok, assurance} ->
      case step.() do
        {:ok, established} -> {:cont, {:ok, Map.merge(assurance, established)}}
        {:error, {status, reason}} -> {:halt, {:error, status, reason, assurance}}
      end
    end)
  end

  defp check_digest(observation, raw) do
    recorded = Map.get(observation, :evidence_digest)
    actual = :crypto.hash(:sha256, raw)

    if is_binary(recorded) and recorded == actual do
      {:ok, %{evidence_integrity: :established}}
    else
      {:error, {:rejected, :evidence_integrity_failure}}
    end
  end

  # The semantic check parses the evidence independently and compares it with
  # the forecast's declared outcome space. It does not trust the adapter's
  # parsed `observed_outcome`.
  defp check_semantics(observation, raw, forecast) do
    case Jason.decode(raw) do
      {:ok, %{"outcome" => observed}} when is_binary(observed) ->
        outcomes = forecast.outcomes || []

        cond do
          outcomes == [] ->
            {:error, {:requires_review, :outcome_definition_missing}}

          observed not in outcomes ->
            {:error, {:rejected, :observation_outside_outcome_definition}}

          observed != Map.get(observation, :observed_outcome) ->
            {:error, {:rejected, :observation_disagrees_with_evidence}}

          true ->
            {:ok, %{semantic_verification: :established, observed_value: observed}}
        end

      {:ok, _other} ->
        {:error, {:rejected, :evidence_schema_invalid}}

      {:error, _reason} ->
        {:error, {:rejected, :evidence_parse_failed}}
    end
  end

  defp check_temporal(observation, forecast) do
    case forecast.typed_horizon do
      nil ->
        {:error, {:requires_review, :typed_horizon_missing}}

      %Horizon{} = horizon ->
        event_at = Map.get(observation, :event_at)
        published_at = Map.get(observation, :published_at)

        cond do
          is_nil(event_at) ->
            {:error, {:unverified, :event_timestamp_missing}}

          not Horizon.event_within?(horizon, event_at) ->
            {:error, {:rejected, :event_outside_horizon}}

          not is_nil(published_at) and
              not Horizon.publication_eligible?(horizon, published_at) ->
            {:error, {:rejected, :publication_outside_policy}}

          true ->
            {:ok, %{temporal_eligibility: :established}}
        end
    end
  end

  defp check_source(observation) do
    case Map.get(observation, :source_identity) do
      identity when is_binary(identity) and identity != "" ->
        {:ok,
         %{
           source_identity: :declared,
           source_identity_authenticated: :not_established,
           transport_protection: :not_established
         }}

      _ ->
        {:error, {:unverified, :source_identity_missing}}
    end
  end

  # ------------------------------------------------------------- result

  defp result(forecast, observation, assurance, status, reason) do
    verification = %{
      forecast_id: forecast.id,
      forecast_digest: Forecast.digest(forecast),
      outcome_definition_digest: forecast.outcome_definition_digest,
      horizon_digest: forecast.horizon_digest,
      observation_id: Map.get(observation, :observation_id),
      observation_digest: Tiannara.Forecasting.Outcome.content_digest(observation),
      evidence_digest: Map.get(observation, :evidence_digest),
      source_identity: Map.get(observation, :source_identity),
      verification_policy_version: @policy_version,
      assurance: assurance,
      status: status,
      reason: reason,
      verified_at: DateTime.utc_now()
    }

    Map.put(verification, :record_digest, record_digest(verification))
  end

  # ------------------------------------------------------------- binding

  defp check_binding(verification, observation) do
    cond do
      Map.get(verification, :observation_id) != Map.get(observation, :observation_id) ->
        {:error, :verification_observation_mismatch}

      Map.get(verification, :evidence_digest) != Map.get(observation, :evidence_digest) ->
        {:error, :verification_evidence_mismatch}

      Map.get(verification, :forecast_id) != Map.get(observation, :forecast_id) ->
        {:error, :verification_forecast_mismatch}

      Map.get(verification, :forecast_digest) != Map.get(observation, :forecast_digest) ->
        {:error, :verification_forecast_digest_mismatch}

      # The observation's content must be exactly what was verified. Without
      # this, an observation could be verified and then have its observed
      # value or timestamps changed before resolution.
      Map.get(verification, :observation_digest) !=
          Tiannara.Forecasting.Outcome.content_digest(observation) ->
        {:error, :observation_content_tampered}

      true ->
        :ok
    end
  end

  # Binding check for the verification transition: the record must be bound
  # to the observation it is being applied to. This is distinct from the
  # verifier's own binding check (which compares the observation against the
  # registered forecast).
  defp check_apply_binding(verification, observation) do
    cond do
      Map.get(verification, :observation_id) != Map.get(observation, :observation_id) ->
        {:error, :verification_observation_mismatch}

      Map.get(verification, :evidence_digest) != Map.get(observation, :evidence_digest) ->
        {:error, :verification_evidence_mismatch}

      Map.get(verification, :forecast_id) != Map.get(observation, :forecast_id) ->
        {:error, :verification_forecast_mismatch}

      Map.get(verification, :forecast_digest) != Map.get(observation, :forecast_digest) ->
        {:error, :verification_forecast_digest_mismatch}

      Map.get(verification, :observation_digest) != Tiannara.Forecasting.Outcome.content_digest(observation) ->
        {:error, :observation_content_tampered}

      true ->
        :ok
    end
  end

  defp check_policy(verification) do
    case Map.get(verification, :verification_policy_version) do
      @policy_version -> :ok
      _other -> {:error, :verification_policy_unsupported}
    end
  end

  defp check_record_digest(verification) do
    recorded = Map.get(verification, :record_digest)

    if is_binary(recorded) and recorded == record_digest(verification) do
      :ok
    else
      {:error, :verification_record_tampered}
    end
  end
end
