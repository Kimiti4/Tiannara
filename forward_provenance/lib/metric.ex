defmodule TiannaraOS.Provenance.Metric do
  @moduledoc """
  Metric identity and derivation provenance.

  A metric is defined by a metric manifest (name, definition_version,
  computation_hash, input_field_list, aggregation method, operation on raw
  samples) and *persisted as a raw measurement corpus* so the derived metric
  can be recomputed independently.

  Fixes: metric value present but raw corpus absent (the T0 gap that made
  gc_009/gc_012 non-reproducible), metric_substitution (test H), wrong-metric
  attribution.
  """

  alias TiannaraOS.Provenance.Canon
  alias TiannaraOS.Provenance.Envelope
  alias TiannaraOS.Provenance.Identity

  @doc """
  Compute a metric from a raw sample list (persisted separately as the corpus)
  under a manifest whose `computation_hash` pins the exact aggregation code.
  Returns a metric identity object + the envelope recording the computation
  with the input corpus hash.
  """
  def compute(opts) do
    name = Keyword.fetch!(opts, :name)
    definition_version = Keyword.get(opts, :definition_version, "1.0.0")
    aggregation = Keyword.fetch!(opts, :aggregation)       # e.g. "mean_stddev"
    input_field = Keyword.fetch!(opts, :input_field)       # e.g. "entropy_samples"
    raw_samples = Keyword.fetch!(opts, :raw_samples)
    rounding = Keyword.get(opts, :rounding, 6)
    seeds = Keyword.get(opts, :seeds)                       # optional
    producer = Keyword.get(opts, :producer)
    parent_envelope_id = Keyword.get(opts, :parent_envelope_id)

    computation_hash = Canon.sha256(%{
      "metric" => name,
      "aggregation" => aggregation,
      "input_field" => input_field,
      "rounding" => rounding,
      "op" => "tiannara-fp-aggregate-v1"
    })

    corpus = Enum.map(raw_samples, &float_round_if/1)
    corpus_sha = Canon.sha256(corpus)

    %{"mean" => mean, "std_dev" => std_dev} =
      do_aggregate(aggregation, corpus, rounding)

    metric_id = Identity.object_id("metric", %{
      "name" => name,
      "definition_version" => definition_version,
      "computation_hash" => computation_hash,
      "aggregation" => aggregation,
      "input_field" => input_field,
      "rounding" => rounding,
      "corpus_sha256" => corpus_sha,
      "seed" => seeds
    })

    envelope = Envelope.build(
      event_type: "metric_computed",
      producer: producer,
      parent_envelope_id: parent_envelope_id,
      body: %{
        "metric_id" => metric_id["object_hash"],
        "name" => name,
        "value_mean" => mean,
        "value_std_dev" => std_dev,
        "corpus_sha256" => corpus_sha,
        "sample_count" => length(corpus),
        "computation_hash" => computation_hash,
        "rounding" => rounding
      },
      bindings: %{"metric" => metric_id}
    )

    %{
      "metric_id" => metric_id,
      "envelope" => envelope,
      "value" => %{"mean" => mean, "std_dev" => std_dev},
      "corpus" => corpus,
      "corpus_sha256" => corpus_sha
    }
  end

  defp float_round_if(f) when is_float(f), do: round_float(f, 10)
  defp float_round_if(x), do: x

  defp round_float(f, _d) when is_float(f), do: f
  defp round_float(x, _d), do: x

  defp do_aggregate("mean_stddev", corpus, rounding) do
    n = length(corpus)
    mean = Enum.sum(corpus) / n |> Float.round(rounding)
    variance = corpus |> Enum.map(fn x -> :math.pow(x - mean, 2) end) |> Enum.sum() |> Kernel./(n)
    std_dev = :math.sqrt(variance) |> Float.round(rounding)
    %{"mean" => mean, "std_dev" => std_dev}
  end
end