defmodule Tiannara.REA.Causal.ChannelFitness do
  @moduledoc """
  Accumulates the empirical utility of a causal channel over time.
  Used in REA-2.5 to map the ecology of causal pathways before evolving them.
  """
  
  @type t :: %__MODULE__{
    channel_id: binary(),
    information_gain: float(),
    predictive_power: float(),
    collapse_correlation: float(),
    novelty_generation: float(),
    samples_collected: non_neg_integer()
  }
  
  defstruct [
    :channel_id,
    information_gain: 0.0,
    predictive_power: 0.0,
    collapse_correlation: 0.0,
    novelty_generation: 0.0,
    samples_collected: 0
  ]
  
  @doc "Initialize a fresh fitness tracker for a channel."
  @spec init(binary()) :: t()
  def init(channel_id) do
    %__MODULE__{channel_id: channel_id}
  end
  
  @doc """
  Update the tracker based on a new observation.
  Observation includes variance (info gain), correlation with fitness, etc.
  """
  def observe(%__MODULE__{} = tracker, obs) do
    n = tracker.samples_collected
    new_n = n + 1
    
    # Moving average
    update_avg = fn old, new_val -> (old * n + new_val) / new_n end
    
    %{tracker |
      information_gain: update_avg.(tracker.information_gain, Map.get(obs, :variance, 0.0)),
      predictive_power: update_avg.(tracker.predictive_power, Map.get(obs, :correlation, 0.0)),
      collapse_correlation: update_avg.(tracker.collapse_correlation, Map.get(obs, :collapse_match, 0.0)),
      novelty_generation: update_avg.(tracker.novelty_generation, Map.get(obs, :novelty, 0.0)),
      samples_collected: new_n
    }
  end
  
  @doc "Compute a single scalar fitness score from the metrics."
  def score(%__MODULE__{} = tf) do
    # Simply sum the metrics. In REA-3 this could be evolved.
    (tf.information_gain * 0.2) + 
    (tf.predictive_power * 0.4) + 
    (tf.collapse_correlation * 0.3) + 
    (tf.novelty_generation * 0.1)
  end
end
