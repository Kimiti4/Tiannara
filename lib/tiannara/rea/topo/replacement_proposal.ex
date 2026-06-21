defmodule Tiannara.REA.Topo.ReplacementProposal do
  @moduledoc """
  A MetaGenome's proposal to replace a Structural channel with an alternative pathway.

  Example: if `civilization_truth_to_epistemic_stability` is Structural (replaceable = 0.333),
  a MetaGenome might propose `civilization_cohesion_to_epistemic_stability` as a replacement.

  Proposals are evaluated over a window of epochs. If the replacement pathway
  consistently produces equal or better stabilization than the original,
  the original channel is demoted and the replacement promoted.
  """

  @type t :: %__MODULE__{
    id: binary(),
    proposer_genome_id: binary(),
    target_channel_id: binary(),
    proposed_channel: map(), # Tiannara.REA.Causal.Channel.t() equivalent
    wins: non_neg_integer(),
    losses: non_neg_integer(),
    evaluation_windows: non_neg_integer(),
    status: :testing | :proven | :failed
  }

  defstruct [
    :id,
    :proposer_genome_id,
    :target_channel_id,
    :proposed_channel,
    wins: 0,
    losses: 0,
    evaluation_windows: 0,
    status: :testing
  ]

  @doc "Create a new replacement proposal."
  @spec new(binary(), binary(), map()) :: t()
  def new(proposer_genome_id, target_channel_id, proposed_channel) do
    %__MODULE__{
      id: :crypto.strong_rand_bytes(8) |> Base.encode16(case: :lower),
      proposer_genome_id: proposer_genome_id,
      target_channel_id: target_channel_id,
      proposed_channel: proposed_channel
    }
  end

  @doc "Evaluate proposal against baseline in current epoch."
  @spec evaluate(t(), float(), float()) :: t()
  def evaluate(%__MODULE__{} = proposal, replacement_effect, baseline_effect) do
    wins = if replacement_effect >= baseline_effect * 0.95, do: 1, else: 0
    losses = if wins == 0, do: 1, else: 0

    new_wins = proposal.wins + wins
    new_losses = proposal.losses + losses
    new_windows = proposal.evaluation_windows + 1

    new_status = cond do
      new_windows >= 50 and new_wins / new_windows >= 0.75 -> :proven
      new_windows >= 50 and new_losses / new_windows >= 0.75 -> :failed
      true -> :testing
    end

    %{proposal |
      wins: new_wins,
      losses: new_losses,
      evaluation_windows: new_windows,
      status: new_status
    }
  end
end
