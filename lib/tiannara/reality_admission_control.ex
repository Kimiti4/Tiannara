defmodule Tiannara.RealityAdmissionControl do
  @moduledoc """
  Reality Admission Control (RAC) — fail-closed epistemic defense.

  RAC never treats a requested check, a caller-supplied status flag, or a
  descriptive placeholder as evidence. ACM and OAVL must be supplied by
  configured checker modules that return evidence-bearing PASS results.
  UMSC performs local uncertainty-contract checks. World Model admission is
  a separate configured adapter and occurs only after every check passes.
  """

  @acm_key :rac_acm_checker
  @oavl_key :rac_oavl_checker
  @world_model_key :rac_world_model_adapter

  @type check_result :: %{
          status: :pass | :fail | :unknown,
          evidence: [map()],
          reason: term()
        }

  @doc """
  Run the configured adversarial checks for a conclusion.

  A conclusion must provide a map containing a non-empty `statement`, numeric
  `confidence` and `uncertainty` values in [0, 1], and a non-empty evidence
  list. ACM/OAVL are deliberately UNKNOWN when their trusted adapters are not
  configured. A result is not admitted by this function.
  """
  def challenge_conclusion(domain_output, source_domain \\ :unknown) do
    challenge = %{
      output: domain_output,
      source: source_domain,
      challenged_at: DateTime.utc_now()
    }

    acm = run_external_check(@acm_key, challenge)
    oavl = run_external_check(@oavl_key, challenge)
    umsc = umsc_uncertainty_check(challenge)

    statuses = %{acm: acm.status, oavl: oavl.status, umsc: umsc.status}

    decision =
      if Enum.all?(Map.values(statuses), &(&1 == :pass)),
        do: :eligible_for_admission,
        else: :rejected_or_unverified

    {:challenged,
     %{
       output: domain_output,
       source: source_domain,
       checks: %{acm: acm, oavl: oavl, umsc: umsc},
       statuses: statuses,
       admission_decision: decision
     }}
  end

  @doc """
  ACM adapter contract: `check(challenge)` returns
  `{:ok, %{status: :pass, evidence: [non_empty_map, ...]}}` only after it
  independently checks cross-source/ontology consistency.
  """
  def acm_consistency_check(challenged_conclusion) do
    run_external_check(@acm_key, normalize_challenge(challenged_conclusion))
  end

  @doc """
  OAVL adapter contract: `check(challenge)` returns an evidence-bearing PASS
  only after semantic assumptions have been adversarially challenged.
  """
  def oavl_semantic_challenge(challenged_conclusion) do
    run_external_check(@oavl_key, normalize_challenge(challenged_conclusion))
  end

  @doc """
  Validate uncertainty bounds locally. Confidence and uncertainty must both be
  explicit and bounded; their sum may not exceed 1. Evidence must be present.
  This is a contract check, not proof that the underlying claim is true.
  """
  def umsc_uncertainty_check(challenged_conclusion) do
    output = Map.get(challenged_conclusion, :output, challenged_conclusion)

    with true <- is_map(output),
         statement when is_binary(statement) <- Map.get(output, :statement),
         true <- String.trim(statement) != "",
         confidence when is_number(confidence) and confidence >= 0 and confidence <= 1 <-
           Map.get(output, :confidence),
         uncertainty when is_number(uncertainty) and uncertainty >= 0 and uncertainty <= 1 <-
           Map.get(output, :uncertainty),
         evidence when is_list(evidence) and evidence != [] <- Map.get(output, :evidence),
         true <- confidence + uncertainty <= 1.0 do
      check(:pass, [%{
        check: :uncertainty_contract,
        statement_present: true,
        confidence: confidence,
        uncertainty: uncertainty,
        evidence_count: length(evidence)
      }], nil)
    else
      false ->
        check(:fail, [], :confidence_exceeds_complement_of_uncertainty)

      _ ->
        check(:fail, [], :missing_or_invalid_uncertainty_contract)
    end
  end

  @doc """
  Admit a conclusion only after RAC independently reruns its checks.

  `opts` is reserved for call-site metadata; it cannot override check results.
  The configured World Model adapter must implement `admit/1` and return
  `{:ok, receipt}`. Without that adapter, admission fails closed.
  """
  def admit_to_world_model(conclusion, source_domain, opts) when is_list(opts) do
    case challenge_conclusion(conclusion, source_domain) do
      {:challenged, %{admission_decision: :eligible_for_admission} = result} ->
        case Application.get_env(:tiannara, @world_model_key) do
          adapter when is_atom(adapter) and not is_nil(adapter) ->
            if Code.ensure_loaded?(adapter) and function_exported?(adapter, :admit, 1) do
              invoke_admission(adapter, Map.put(result, :metadata, Map.new(opts)))
            else
              {:error, :invalid_world_model_adapter}
            end

          _ ->
            {:error, :world_model_unavailable}
        end

      {:challenged, result} ->
        {:error, {:rac_checks_not_passed, result.statuses}}
    end
  end

  def admit_to_world_model(_conclusion, _source_domain, _opts),
    do: {:error, :invalid_admission_options}

  @doc """
  Compatibility entry point. The single-argument form uses the same fail-closed
  pipeline and does not trust pre-populated status fields.
  """
  def admit_to_world_model(conclusion) when is_map(conclusion) do
    admit_to_world_model(conclusion, Map.get(conclusion, :source, :unknown), [])
  end

  def admit_to_world_model(_), do: {:error, :invalid_conclusion}

  def reject_from_world_model(failed_conclusion, reason) do
    {:error, :rejected, reason, failed_conclusion}
  end

  defp run_external_check(config_key, challenge) do
    case Application.get_env(:tiannara, config_key) do
      checker when is_atom(checker) and not is_nil(checker) ->
        if Code.ensure_loaded?(checker) and function_exported?(checker, :check, 1) do
          try do
            case checker.check(challenge) do
              {:ok, %{status: :pass, evidence: evidence}} when is_list(evidence) and evidence != [] ->
                check(:pass, evidence, nil)

              {:ok, %{status: :fail} = result} ->
                check(:fail, Map.get(result, :evidence, []), Map.get(result, :reason, :check_failed))

              {:ok, _} ->
                check(:unknown, [], :checker_returned_no_verifiable_evidence)

              {:error, reason} ->
                check(:unknown, [], {:checker_error, reason})

              _ ->
                check(:unknown, [], :invalid_checker_result)
            end
          rescue
            error -> check(:unknown, [], {:checker_exception, error.__struct__})
          catch
            kind, _reason -> check(:unknown, [], {:checker_failure, kind})
          end
        else
          check(:unknown, [], :invalid_checker)
        end

      _ ->
        check(:unknown, [], :checker_unavailable)
    end
  end

  defp invoke_admission(adapter, result) do
    case adapter.admit(result) do
      {:ok, receipt} -> {:ok, :admitted_to_world_model, result, receipt}
      {:error, reason} -> {:error, {:world_model_admission_failed, reason}}
      _ -> {:error, :invalid_world_model_receipt}
    end
  rescue
    error -> {:error, {:world_model_adapter_exception, error.__struct__}}
  catch
    kind, _reason -> {:error, {:world_model_adapter_failure, kind}}
  end

  defp normalize_challenge(%{output: _output} = challenge), do: challenge
  defp normalize_challenge(output), do: %{output: output, source: :unknown}

  defp check(status, evidence, reason) do
    %{status: status, evidence: evidence, reason: reason}
  end
end
