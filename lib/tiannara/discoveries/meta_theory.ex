defmodule Tiannara.REA.TheoryEpisode do
  @derive Jason.Encoder
  defstruct [
    :context,           # %{volatility: float, complexity: float, adversariality: float}
    :selected_theory,   # string (theory_id)
    :confidence,        # float
    :validation_result, # :success | :failure
    :survival_delta,    # float
    :domain,            # atom
    :outcome            # string
  ]
end

defmodule Tiannara.REA.MetaTheoryTensor do
  @derive Jason.Encoder
  defstruct [
    :trusted_theories,         # list of strings
    :failed_theories,          # list of strings
    :theory_trust_weights,     # map of string => float
    :convergence_scores,       # map of string => float
    :transferability_scores,   # map of string => float
    :hazard_ratios,            # map of string => float
    :reproductive_numbers,     # map of string => float
    :environmental_histories,  # list of maps
    :recommendation_history,   # list of maps
    :selection_history,        # list of TheoryEpisode
    :theory_ages,              # map of string => integer
    :theory_generations,       # map of string => integer
    :lifetime_validations      # map of string => integer
  ]
end

defmodule Tiannara.REA.MetaTheoryExtractor do
  @moduledoc """
  Extracts theory properties to construct the initial MetaTheoryTensor state.
  """
  alias Tiannara.REA.MetaTheoryTensor

  def extract(theories, histories \\ []) do
    theory_ids = Enum.map(theories, fn t ->
      cond do
        Map.has_key?(t, :theory_id) -> t.theory_id
        Map.has_key?(t, :id) -> to_string(t.id)
        true -> "unknown"
      end
    end)

    state =
      case Process.whereis(TiannaraOS.CivilizationKernel) do
        nil -> nil
        pid ->
          if Process.alive?(pid) do
            try do
              apply(TiannaraOS.CivilizationKernel, :get_state, [])
            rescue
              _ -> nil
            end
          else
            nil
          end
      end

    {trusts, convergences, transferabilities, hazards, reproductions} =
      if state do
        {
          Map.new(theories, fn t ->
            tid = cond do
              Map.has_key?(t, :theory_id) -> t.theory_id
              Map.has_key?(t, :id) -> to_string(t.id)
              true -> "unknown"
            end

            atom_id = String.to_atom(tid)
            val =
              case Map.get(state.evidence_graph, atom_id) do
                %{value: v} when is_number(v) -> v
                _ -> 0.50
              end
            {tid, val}
          end),

          Map.new(theories, fn t ->
            tid = cond do
              Map.has_key?(t, :theory_id) -> t.theory_id
              Map.has_key?(t, :id) -> to_string(t.id)
              true -> "unknown"
            end

            atom_id = String.to_atom(tid)
            claim_vals =
              case Map.get(state.evidence_graph, atom_id) do
                %{dependents: deps} ->
                  deps
                  |> Enum.map(&Map.get(state.evidence_graph, &1))
                  |> Enum.filter(&(&1 != nil and &1.type == :claim))
                  |> Enum.map(&(&1.value || 0.5))
                _ -> []
              end
            val = if length(claim_vals) > 0, do: Enum.sum(claim_vals) / length(claim_vals), else: 0.10
            {tid, val}
          end),

          Map.new(theories, fn t ->
            tid = cond do
              Map.has_key?(t, :theory_id) -> t.theory_id
              Map.has_key?(t, :id) -> to_string(t.id)
              true -> "unknown"
            end

            disc_levels =
              state.discoveries
              |> Map.values()
              |> Enum.filter(&(&1.theory_id == tid or to_string(&1.id) == tid))
              |> Enum.map(fn d ->
                case d.validation_level do
                  :L1 -> 0.2
                  :L2 -> 0.4
                  :L3 -> 0.6
                  :L4 -> 0.8
                  :L5 -> 1.0
                  _ -> 0.5
                end
              end)
            val = if length(disc_levels) > 0, do: Enum.sum(disc_levels) / length(disc_levels), else: 0.50
            {tid, val}
          end),

          Map.new(theories, fn t ->
            tid = cond do
              Map.has_key?(t, :theory_id) -> t.theory_id
              Map.has_key?(t, :id) -> to_string(t.id)
              true -> "unknown"
            end

            atom_id = String.to_atom(tid)
            replications =
              case Map.get(state.evidence_graph, atom_id) do
                %{dependents: deps} ->
                  deps
                  |> Enum.map(&Map.get(state.evidence_graph, &1))
                  |> Enum.filter(&(&1 != nil and &1.type == :replication))
                _ -> []
              end
            failed_rep = Enum.count(replications, &(&1.value == 0.0))
            val = if length(replications) > 0, do: failed_rep / length(replications), else: 0.10
            {tid, val}
          end),

          Map.new(theories, fn t ->
            tid = cond do
              Map.has_key?(t, :theory_id) -> t.theory_id
              Map.has_key?(t, :id) -> to_string(t.id)
              true -> "unknown"
            end

            atom_id = String.to_atom(tid)
            val =
              case Map.get(state.evidence_graph, atom_id) do
                %{dependents: deps} -> min(1.0, length(deps) / 10.0)
                _ -> 0.20
              end
            {tid, val}
          end)
        }
      else
        {
          Map.new(theories, fn t -> {if(Map.has_key?(t, :theory_id), do: t.theory_id, else: to_string(t.id)), 0.50} end),
          Map.new(theories, fn t -> {if(Map.has_key?(t, :theory_id), do: t.theory_id, else: to_string(t.id)), 0.10} end),
          Map.new(theories, fn t -> {if(Map.has_key?(t, :theory_id), do: t.theory_id, else: to_string(t.id)), 0.50} end),
          Map.new(theories, fn t -> {if(Map.has_key?(t, :theory_id), do: t.theory_id, else: to_string(t.id)), 0.10} end),
          Map.new(theories, fn t -> {if(Map.has_key?(t, :theory_id), do: t.theory_id, else: to_string(t.id)), 0.20} end)
        }
      end

    ages = Map.new(theories, fn t -> {if(Map.has_key?(t, :theory_id), do: t.theory_id, else: to_string(t.id)), Map.get(t, :lifetime, 1) || 1} end)
    generations = Map.new(theories, fn t -> {if(Map.has_key?(t, :theory_id), do: t.theory_id, else: to_string(t.id)), Map.get(t, :generation, 1) || 1} end)
    validations = Map.new(theories, fn t -> {if(Map.has_key?(t, :theory_id), do: t.theory_id, else: to_string(t.id)), length(Map.get(t, :validation_history, []) || [])} end)

    %MetaTheoryTensor{
      trusted_theories: theory_ids,
      failed_theories: [],
      theory_trust_weights: trusts,
      convergence_scores: convergences,
      transferability_scores: transferabilities,
      hazard_ratios: hazards,
      reproductive_numbers: reproductions,
      environmental_histories: histories,
      recommendation_history: [],
      selection_history: [],
      theory_ages: ages,
      theory_generations: generations,
      lifetime_validations: validations
    }
  end
end

defmodule Tiannara.REA.MetaTheoryLearner do
  @moduledoc """
  Updates trust parameters under Laws MT1 (Trust formation), MT2 (Forgetting), MT3 (Transfer), and MT6 (Adversarial).
  """
  alias Tiannara.REA.MetaTheoryTensor
  alias Tiannara.REA.TheoryEpisode

  @eta 0.20
  @beta 0.25

  def learn(%MetaTheoryTensor{} = tensor, theory_id, context, success?, outcome_delta \\ 0.0) do
    current_trust = Map.get(tensor.theory_trust_weights, theory_id, 0.50)
    adv = Map.get(context, :adversariality, 0.0)

    new_trust =
      if success? do
        # MT1 & MT6: Successes under adversariality accelerate trust gain
        gain = @eta * (1.0 - current_trust) * (1.0 + adv)
        min(0.99, current_trust + gain)
      else
        # MT1 & MT6: Failures under extreme hostility decay trust less severely
        loss = @beta * current_trust * (1.0 - 0.5 * adv)
        max(0.01, current_trust - loss)
      end

    updated_trusts = Map.put(tensor.theory_trust_weights, theory_id, Float.round(new_trust, 4))

    trusted = if new_trust >= 0.70, do: Enum.uniq([theory_id | tensor.trusted_theories]), else: List.delete(tensor.trusted_theories, theory_id)
    failed = if new_trust < 0.30, do: Enum.uniq([theory_id | tensor.failed_theories]), else: List.delete(tensor.failed_theories, theory_id)

    # Increment validations
    current_vals = Map.get(tensor.lifetime_validations, theory_id, 0)
    updated_vals = Map.put(tensor.lifetime_validations, theory_id, current_vals + 1)

    # Log Episode
    episode = %TheoryEpisode{
      context: context,
      selected_theory: theory_id,
      confidence: Float.round(current_trust, 4),
      validation_result: if(success?, do: :success, else: :failure),
      survival_delta: outcome_delta,
      domain: Map.get(context, :domain, :unknown),
      outcome: if(success?, do: "Validated successfully in #{Map.get(context, :domain)}", else: "Refuted in #{Map.get(context, :domain)}")
    }

    %{tensor |
      theory_trust_weights: updated_trusts,
      trusted_theories: trusted,
      failed_theories: failed,
      lifetime_validations: updated_vals,
      selection_history: [episode | tensor.selection_history]
    }
  end

  def decay_trust(%MetaTheoryTensor{} = tensor, theory_id, factor \\ 0.05) do
    current_trust = Map.get(tensor.theory_trust_weights, theory_id, 0.50)
    new_trust = max(0.01, Float.round(current_trust * (1.0 - factor), 4))

    updated_trusts = Map.put(tensor.theory_trust_weights, theory_id, new_trust)
    %{tensor | theory_trust_weights: updated_trusts}
  end

  def transfer_trust(%MetaTheoryTensor{} = tensor, theory_id, similarity) do
    current_trust = Map.get(tensor.theory_trust_weights, theory_id, 0.50)
    new_trust = max(0.01, Float.round(current_trust * similarity, 4))

    updated_trusts = Map.put(tensor.theory_trust_weights, theory_id, new_trust)
    %{tensor | theory_trust_weights: updated_trusts}
  end
end

defmodule Tiannara.REA.MetaTheoryPredictor do
  @moduledoc """
  Dynamic Context-Based Predictor implementing Law MT4 and MT7 Portfolio rules.
  """
  alias Tiannara.REA.MetaTheoryTensor

  @domain_similarity %{
    {:energy, :climate} => 0.85,
    {:energy, :security} => 0.60,
    {:energy, :education} => 0.20,
    {:security, :governance} => 0.75,
    {:security, :climate} => 0.30,
    {:economics, :finance} => 0.90,
    {:economics, :governance} => 0.70
  }

  def domain_similarity(d1, d2) do
    cond do
      d1 == d2 -> 1.0
      Map.has_key?(@domain_similarity, {d1, d2}) -> Map.get(@domain_similarity, {d1, d2})
      Map.has_key?(@domain_similarity, {d2, d1}) -> Map.get(@domain_similarity, {d2, d1})
      true -> 0.40
    end
  end

  def theory_focus_context(theory_id) do
    case theory_id do
      "theory_alpha" -> %{volatility: 0.8, complexity: 0.2, adversariality: 0.3, domain: :climate}
      "theory_beta" -> %{volatility: 0.6, complexity: 0.4, adversariality: 0.4, domain: :governance}
      "theory_gamma" -> %{volatility: 0.3, complexity: 0.5, adversariality: 0.7, domain: :security}
      "theory_delta" -> %{volatility: 0.2, complexity: 0.8, adversariality: 0.2, domain: :technology}
      _ -> %{volatility: 0.5, complexity: 0.5, adversariality: 0.5, domain: :unknown}
    end
  end

  @doc """
  Recommends the single optimal theory dynamically using context geometry weights.
  """
  def recommend(%MetaTheoryTensor{} = tensor, context, domain) do
    scores = calculate_theory_scores(tensor, context, domain)

    {best_id, best_score} =
      if scores == %{} do
        {"N/A", 0.0}
      else
        Enum.max_by(scores, &elem(&1, 1))
      end

    %{
      recommended_theory: best_id,
      confidence: Float.round(best_score, 4)
    }
  end

  @doc """
  Calculates adaptive dynamic weights representing MT7 Portfolio proportions.
  """
  def get_adaptive_portfolio_weights(%MetaTheoryTensor{} = tensor, context, domain) do
    scores = calculate_theory_scores(tensor, context, domain)
    total_score = Enum.sum(Map.values(scores))

    if total_score > 0.0 do
      Map.new(scores, fn {tid, sc} -> {tid, Float.round(sc / total_score, 4)} end)
    else
      Map.new(Map.keys(scores), & {&1, 1.0 / length(Map.keys(scores))})
    end
  end

  defp calculate_theory_scores(%MetaTheoryTensor{} = tensor, context, domain) do
    Map.new(tensor.theory_trust_weights, fn {tid, trust} ->
      focus = theory_focus_context(tid)

      # 1. Compute coordinate distance
      v_diff = :math.pow(focus.volatility - Map.get(context, :volatility, 0.5), 2)
      c_diff = :math.pow(focus.complexity - Map.get(context, :complexity, 0.5), 2)
      a_diff = :math.pow(focus.adversariality - Map.get(context, :adversariality, 0.5), 2)
      coord_dist = :math.sqrt(v_diff + c_diff + a_diff)

      # 2. Add domain similarity distance
      d_domain = 1.0 - domain_similarity(focus.domain, domain)
      total_dist = coord_dist + d_domain

      # 3. Retrieve bounding metrics
      cdr = Map.get(tensor.transferability_scores, tid, 0.50)
      hr = Map.get(tensor.hazard_ratios, tid, 0.10)
      rt = Map.get(tensor.reproductive_numbers, tid, 0.20)

      # 4. Apply transformations
      hr_adj = 1.0 / (1.0 + hr)
      rt_adj = rt / (1.0 + rt)

      score = trust * cdr * hr_adj * rt_adj * max(0.01, 1.0 - total_dist)
      {tid, score}
    end)
  end
end
