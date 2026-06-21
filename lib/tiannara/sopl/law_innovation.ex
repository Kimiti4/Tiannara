defmodule Tiannara.SOPL.LawInnovation do
  @moduledoc """
  SOPL-3: Law Innovation
  
  Tracks genuinely new law-space recombinations. Utilizes the Legitimacy 
  Filter to ensure that a universe is not just "exotic but sterile."
  """
  defstruct [
    :id,
    :proto_law_id,
    :fragment_ancestry,
    :constitutional_pressure,
    :novelty_score,
    :legitimacy_score,
    :usefulness_score,
    :is_legitimate_innovation
  ]
end

defmodule Tiannara.SOPL.InnovationTracker do
  @moduledoc """
  SOPL-3: Innovation Tracker
  
  Evaluates graduating ProtoLaws against the Legitimacy Filter.
  Ensures that SOPL-3 is actually expanding law-space rather than 
  endlessly recreating Balanced Law E.
  """
  alias Tiannara.SOPL.LawInnovation
  require Logger

  @doc """
  Evaluates a deployed ProtoLaw and records it as an Innovation if it passes the filter.
  Requires the shadow validation pressure and the live ecology fitness metrics.
  """
  def evaluate_innovation(proto_law, shadow_pressure, live_fitness_eval, known_archetypes) do
    # 1. Novelty: Distance from known law-space
    novelty = calculate_novelty(proto_law, known_archetypes)
    
    # 2. Legitimacy: Ability to survive constitutional validation easily
    # A pressure of 0.1 means 0.9 legitimacy.
    legitimacy = 1.0 - shadow_pressure.total_pressure
    
    # 3. Usefulness: Creates productive ecologies
    usefulness = live_fitness_eval.total_fitness
    
    # THE LEGITIMACY FILTER
    # A universe must be novel, constitutionally legitimate, AND productive.
    is_legitimate = (novelty > 0.6) and (legitimacy > 0.7) and (usefulness > 0.6)
    
    innovation = %LawInnovation{
      id: "innov_#{proto_law.id}",
      proto_law_id: proto_law.id,
      fragment_ancestry: proto_law.fragment_ancestry,
      constitutional_pressure: shadow_pressure.total_pressure,
      novelty_score: novelty,
      legitimacy_score: legitimacy,
      usefulness_score: usefulness,
      is_legitimate_innovation: is_legitimate
    }
    
    if is_legitimate do
      Logger.info("💡 [SOPL-3] LEGITIMATE INNOVATION! ProtoLaw #{proto_law.id} expanded law-space. (N: #{Float.round(novelty, 2)}, L: #{Float.round(legitimacy, 2)}, U: #{Float.round(usefulness, 2)})")
    else
      Logger.debug("📉 [SOPL-3] ProtoLaw #{proto_law.id} failed the Legitimacy Filter.")
    end
    
    innovation
  end

  defp calculate_novelty(proto, archetypes) do
    # Compares the fragment signature against known archetypes
    sig = Enum.sort(proto.fragment_ancestry || []) |> Enum.join("+")
    
    if Enum.any?(archetypes, fn a -> a.dominant_fragments == sig end) do
      0.1 # Recreated a known attractor (e.g. Balanced E)
    else
      0.9 # Entirely new synthetic signature
    end
  end
end
