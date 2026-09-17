defmodule TiannaraOS.Provenance.Execution do
  @moduledoc """
  Execution identity and lifecycle envelopes.

  An execution is a sequence of envelopes:
    execution_started  (records source/contract/environment/seed/input manifest)
    execution_ended    (records status + output manifest)

  Fixes: execution_id uniqueness (test F), wrong_source_commit, wrong_seed,
  wrong_configuration, failed_execution_reported_as_success.
  """

  alias TiannaraOS.Provenance.{Envelope, IdentityAuthority}

  def build(opts) do
    source = Keyword.fetch!(opts, :source)
    contract = Keyword.fetch!(opts, :contract)
    environment = Keyword.fetch!(opts, :environment)
    experiment_id = Keyword.fetch!(opts, :experiment_id)
    campaign_id = Keyword.get(opts, :campaign_id)
    seed = Keyword.get(opts, :seed)
    input_manifest = Keyword.get(opts, :input_manifest, [])
    producer = Keyword.get(opts, :producer)

    execution_id =
      case Keyword.fetch(opts, :execution_id) do
        {:ok, id} ->
          # Adopted/external id: must be claimed through the authority and never
          # already owned by another execution.
          case IdentityAuthority.claim(id, producer || "unknown_producer") do
            {:ok, _} ->
              id

            {:error, :duplicate, existing} ->
              raise ArgumentError,
                    "execution_id collision: #{inspect(id)} already claimed by " <>
                      "#{inspect(Map.get(existing, "producer"))} via authority " <>
                      "#{Map.get(existing, "authority")}; an execution id must name " <>
                      "exactly one execution across producers"
          end

        :error ->
          case IdentityAuthority.mint(producer || "unknown_producer") do
            {:error, reason} -> raise ArgumentError, "identity authority mint failed: #{inspect(reason)}"
            {id, _record} -> id
          end
      end

    start_env = Envelope.build(
      event_type: "execution_started",
      producer: producer,
      body: %{
        "execution_id" => execution_id,
        "experiment_id" => experiment_id,
        "campaign_id" => campaign_id,
        "seed" => seed,
        "input_manifest" => input_manifest,
        "status" => "started"
      },
      bindings: %{
        "source" => source,
        "contract" => contract,
        "environment" => environment
      }
    )

    %{
      "execution_id" => execution_id,
      "experiment_id" => experiment_id,
      "campaign_id" => campaign_id,
      "seed" => seed,
      "started" => start_env,
      "ended" => nil,
      "output_manifest" => [],
      "status" => "started"
    }
  end

  @doc "Close the execution with a status and output manifest."
  def finish(execution, opts) do
    status = Keyword.fetch!(opts, :status)
    failure = Keyword.get(opts, :failure)
    output_manifest = Keyword.get(opts, :output_manifest, [])
    end_time = Keyword.get(opts, :ended_at, DateTime.utc_now())

    ended = Envelope.build(
      event_type: "execution_ended",
      producer: Map.get(execution["started"], "producer"),
      parent_envelope_id: execution["started"]["envelope_id"],
      body: %{
        "execution_id" => execution["execution_id"],
        "status" => status,
        "failure" => failure,
        "output_manifest" => output_manifest,
        "ended_at" => DateTime.to_iso8601(end_time)
      }
    )

    %{execution | "ended" => ended, "output_manifest" => output_manifest, "status" => status}
  end

  def envelopes(%{"started" => s} = execution) do
    [s] ++ (if execution["ended"], do: [execution["ended"]], else: [])
  end
end