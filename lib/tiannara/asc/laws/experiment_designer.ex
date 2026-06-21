defmodule Tiannara.ASC.Laws.ExperimentDesigner do
  @moduledoc """
  Phase 5F: Active Hypothesis Testing.
  Analyzes the TransferEcology matrix to identify statistically starved buckets
  and designs targeted experimental conditions to force the collection of high-signal data.
  """
  
  alias Tiannara.ASC.Crucible.TransferEcology
  alias Tiannara.ASC.Laws.Experiment
  require Logger

  @min_bucket_size 30 # Minimum samples per bucket to achieve statistical significance

  @doc """
  Analyzes the current ecology state and returns a list of Experiment definitions
  needed to resolve weak hypotheses.
  """
  def design_experiments do
    gaps = TransferEcology.get_hypothesis_gaps()
    
    experiments = []
    experiments = experiments ++ target_distance_decay(gaps.distance_buckets)
    experiments = experiments ++ target_domain_resonance(gaps.domain_buckets)
    
    experiments
  end

  defp target_distance_decay(buckets) do
    {starved_bucket, count} = Enum.min_by(buckets, fn {_k, v} -> v end)
    
    if count < @min_bucket_size do
      needed = @min_bucket_size - count
      Logger.info("🧪 [ExperimentDesigner] Distance Decay starved in '#{starved_bucket}' (#{count}/#{@min_bucket_size}). Designing experiment with #{needed} repetitions.")
      
      [
        %Experiment{
          bucket: {:distance, starved_bucket},
          repetitions: needed,
          source_domain: :compute,
          target_domain: :compute, # Same domain to isolate distance
          semantic_distance: starved_bucket
        }
      ]
    else
      []
    end
  end

  defp target_domain_resonance(buckets) do
    {starved_bucket, count} = Enum.min_by(buckets, fn {_k, v} -> v end)
    
    if count < @min_bucket_size do
      needed = @min_bucket_size - count
      Logger.info("🧪 [ExperimentDesigner] Domain Resonance starved in '#{starved_bucket}' (#{count}/#{@min_bucket_size}). Designing experiment with #{needed} repetitions.")
      
      {source, target} = if starved_bucket == :cross_domain do
        {:security, :data}
      else
        {:security, :security}
      end

      [
        %Experiment{
          bucket: {:domain, starved_bucket},
          repetitions: needed,
          source_domain: source,
          target_domain: target,
          semantic_distance: :medium # Standardized distance to isolate domain effect
        }
      ]
    else
      []
    end
  end
end
