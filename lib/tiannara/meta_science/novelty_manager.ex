defmodule Tiannara.MetaScience.NoveltyManager do
  @moduledoc "Tracks and rewards epistemic novelty to prevent redundant discovery."
  alias Tiannara.Foundations.InformationTheory

  def calculate_novelty(hypothesis, existing_knowledge_graph) do
    expected_dist = hypothesis.predicted_distributions
    current_dist = existing_knowledge_graph.current_beliefs
    InformationTheory.kl_divergence(expected_dist, current_dist)
  end
end
