defmodule Tiannara.Provenance.DiscoveryLedger do
  @moduledoc """
  Causal provenance for a validated discovery.

  Answers the constitutional question:

      "Why do you believe this is a discovery?"

  ...with an explicit evidence chain rather than a generated narrative.

  Chain reconstructed (read-only, from immutable events):

      validated_discovery <- discovery_candidate <- knowledge_integration
                         <- evidence <- experiment <- experiment_configuration
                         <- prediction <- hypothesis <- gap <- observation

  Constitutional basis:
    * Reproducibility
    * Lineage preservation
    * Evidence Before Confidence
    * Uncertainty must never be hidden
  """

  @required_for_claim [
    :observations,
    :gaps,
    :hypotheses,
    :evidence_generated,
    :validated_discoveries
  ]

  defstruct [
    :discovery_id,
    :chain,
    :stages_present,
    :complete?,
    :confidence,
    :contradictions
  ]

  @type t :: %__MODULE__{}

  @doc """
  Reconstruct the provenance chain for a discovery id from immutable events.
  """
  def reconstruct(discovery_id, events) when is_list(events) do
    index = build_index(events)
    chain = walk(discovery_id, index, [])

    stages_present =
      chain
      |> Enum.map(fn {stage, _id, _meta} -> stage end)
      |> MapSet.new()

    complete? = Enum.all?(@required_for_claim, &MapSet.member?(stages_present, &1))

    confidence = meta_value(chain, :confidence)
    contradictions = meta_value(chain, :contradictions) || []

    %__MODULE__{
      discovery_id: discovery_id,
      chain: chain,
      stages_present: stages_present,
      complete?: complete?,
      confidence: confidence,
      contradictions: contradictions
    }
  end

  @doc """
  Render the evidence chain as ordered, human-auditable statements.
  """
  def why(%__MODULE__{chain: chain}) do
    Enum.map(chain, fn {stage, id, meta} ->
      "#{stage} :: #{inspect(id)}#{format_meta(meta)}"
    end)
  end

  def verdict(%__MODULE__{complete?: true}), do: :provenance_complete
  def verdict(%__MODULE__{complete?: false, stages_present: present}) do
    missing = Enum.reject(@required_for_claim, &MapSet.member?(present, &1))
    {:provenance_incomplete, missing}
  end

  # --- internals -----------------------------------------------------------

  defp build_index(events) do
    base =
      for {:created, stage, id, parents} <- events, into: %{} do
        {id, %{stage: stage, parents: parents, meta: %{}}}
      end

    Enum.reduce(events, base, fn
      {:meta, _stage, id, key, value}, acc ->
        case Map.fetch(acc, id) do
          {:ok, rec} -> Map.put(acc, id, %{rec | meta: Map.put(rec.meta, key, value)})
          :error -> acc
        end

      _other, acc ->
        acc
    end)
  end

  defp walk(id, index, acc) do
    case Map.fetch(index, id) do
      :error ->
        Enum.reverse(acc)

      {:ok, rec} ->
        acc = [{rec.stage, id, rec.meta} | acc]

        case rec.parents do
          [parent | _] -> walk(parent, index, acc)
          [] -> Enum.reverse(acc)
        end
    end
  end

  defp meta_value(chain, key) do
    chain
    |> Enum.reverse()
    |> Enum.find_value(fn {_stage, _id, meta} -> Map.get(meta, key) end)
  end

  defp format_meta(meta) when map_size(meta) == 0, do: ""
  defp format_meta(meta), do: "  #{inspect(meta)}"
end
