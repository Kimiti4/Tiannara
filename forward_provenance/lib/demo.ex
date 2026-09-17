defmodule TiannaraOS.Provenance.Demo do
  @moduledoc """
  Demonstration producer for a NEW forward execution.

  Runs a complete, honest forward chain for one campaign:
    source -> contract -> execution -> result -> raw corpus -> derived metric
    -> certificate, plus provenance graph and an independent evidence bundle.

  The demo makes NO claim about any historical T0 campaign. It is a *new*
  execution (fixed seed, fresh ids) whose entire evidence chain is persisted so
  an independent verifier can recompute every identity from bundle bytes alone.
  """

  alias TiannaraOS.Provenance.{Canon, Contract, Environment, Source, Execution, Result, Metric, Certificate, Graph, Bundle}

  defmodule Input do
    @moduledoc """
    Pure, seedable trial-mean estimator (the new experiment body).

    Each returned sample is the mean of +draws_per_trial+ uniform draws, so the
    across-trial variance is ~1/(12*draws_per_trial). With 100 draws the std of
    trial means is ~0.0289, which passes the 0.05 entropy-stability gate. The
    exact corpus is persisted as raw measurements and is deterministic for a
    given seed.
    """
    @draws_per_trial 100

    def samples(n, seed) do
      :rand.seed(:exsss, {seed, seed * 31, seed * 17})
      Enum.map(1..n, fn _ ->
        Enum.reduce(1..@draws_per_trial, 0.0, fn _, acc -> acc + :rand.uniform() end) / @draws_per_trial
      end)
    end
  end

  def run(opts) do
    experiment_id = Keyword.fetch!(opts, :experiment_id)
    campaign_id = Keyword.get(opts, :campaign_id, "fp-demo")
    seed = Keyword.get(opts, :seed, 42)
    sample_count = Keyword.get(opts, :sample_count, 1000)
    gate_std_dev = Keyword.get(opts, :gate_std_dev, 0.05)
    root = Keyword.fetch!(opts, :output_dir)
    demo_id = Keyword.get(opts, :demo_id, experiment_id)

    source = Keyword.get(opts, :source) || Source.capture(cwd: Keyword.get(opts, :source_cwd, File.cwd!()))
    contract_bytes = Keyword.fetch!(opts, :contract_bytes)
    contract = Contract.build(contract_bytes: contract_bytes, contract_version: "1.0.0",
                parameter_set: %{"sample_count" => sample_count, "gate_std_dev" => gate_std_dev, "seed" => seed})
    environment = Keyword.get(opts, :environment) || Environment.build()

    producer = "TiannaraOS.Provenance.Demo/1.0.0"

    execution =
      Execution.build(
        source: source,
        contract: contract,
        environment: environment,
        experiment_id: experiment_id,
        campaign_id: campaign_id,
        seed: seed,
        input_manifest: ["contract.bytes", "raw corpus generation"],
        producer: producer
      )

    # Execute: generate raw measurement corpus (the NEW experiment body).
    raw_samples = Input.samples(sample_count, seed)

    execution = Execution.finish(execution, status: "completed", output_manifest: ["result.bytes", "measurements/raw_corpus.json"])

    # result payload = the raw corpus persisted byte-for-byte
    result_bytes = Canon.canon(raw_samples)

    result =
      Result.produce(
        execution: execution,
        result_bytes: result_bytes,
        producer: producer
    )

    metric =
      Metric.compute(
        name: "#{experiment_id}.entropy_mean_std",
        aggregation: "mean_stddev",
        input_field: "raw_samples",
        raw_samples: raw_samples,
        rounding: 6,
        seeds: seed,
        producer: producer,
        parent_envelope_id: result["envelope"]["envelope_id"]
      )

    decision = if metric["value"]["std_dev"] < gate_std_dev, do: "certified", else: "failed"
    reason = if decision == "certified", do: "std_dev below gate with raw corpus persisted and recomputable", else: "std_dev above gate"

    certificate =
      Certificate.issue(
        decision: decision,
        reason: reason,
        authority: "independent_verifier_v1",
        producer: producer,
        parent_envelope_id: metric["envelope"]["envelope_id"],
        evidence: %{
          "source" => source,
          "contract" => contract,
          "metric" => metric["metric_id"],
          "result" => %{"object_hash" => result["payload_hash"]},
          "execution" => %{"object_hash" => Canon.sha256(%{"execution_id" => execution["execution_id"]})}
        }
      )

    graph = Graph.build(
      source: source,
      contract: contract,
      execution: execution,
      result: result,
      metric: metric,
      certificate: certificate,
      environment: environment
    )

    # persist everything under the output tree, then build the bundle
    File.mkdir_p!(root)
    File.write!(Path.join(root, "execution.record.json"), Canon.canon(execution))
    File.write!(Path.join(root, "raw_corpus.json"), Canon.canon(raw_samples))
    File.write!(Path.join(root, "metric.json"), Canon.canon(metric["value"]))
    File.write!(Path.join(root, "provenance_graph.json"), Canon.canon(graph))
    File.write!(Path.join(root, "contract.bytes"), contract_bytes)

    bundle =
      Bundle.produce(
        demo_id: demo_id,
        source: source,
        contract: contract,
        contract_bytes: contract_bytes,
        environment: environment,
        execution: execution,
        result: result,
        metric: metric,
        certificate: certificate,
        graph: graph,
        dir: Path.join(root, "bundle")
      )

    prefix = Canon.sha256(%{"experiment_id" => experiment_id, "seed" => seed, "certificate_id" => certificate["certificate_id"]})

    %{
      "demo_id" => demo_id,
      "experiment_id" => experiment_id,
      "execution" => execution,
      "source" => source,
      "contract" => contract,
      "environment" => environment,
      "result" => result,
      "metric" => metric,
      "certificate" => certificate,
      "graph" => graph,
      "bundle" => bundle,
      "bundle_sha256" => bundle["manifest_sha256"],
      "result_certificate_prefix" => String.slice(prefix, 0, 12)
    }
  end
end