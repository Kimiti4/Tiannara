defmodule Tiannara.Discovery.ExperimentPlanner do
  alias Tiannara.Discovery.Domain.{HypothesisSpec, PredictionSpec, ExperimentPlan}

  @spec plan(HypothesisSpec.t(), [PredictionSpec.t()]) :: [ExperimentPlan.t()]
  def plan(%HypothesisSpec{} = hypothesis, predictions) when is_list(predictions) do
    predictions
    |> Enum.map(fn prediction -> design_experiment(hypothesis, prediction) end)
    |> Enum.reject(&is_nil/1)
  end

  @spec plan_for_hypotheses(%{String.t() => [PredictionSpec.t()]}, [HypothesisSpec.t()]) ::
          %{String.t() => [ExperimentPlan.t()]}
  def plan_for_hypotheses(predictions_by_hyp, hypotheses) when is_map(predictions_by_hyp) do
    Map.new(hypotheses, fn hyp ->
      predictions = Map.get(predictions_by_hyp, hyp.id, [])
      {hyp.id, plan(hyp, predictions)}
    end)
  end

  @spec estimate_total_cost([ExperimentPlan.t()]) :: map()
  def estimate_total_cost(experiments) when is_list(experiments) do
    Enum.reduce(experiments, %{compute: 0, memory: 0, time_hours: 0, energy: 0}, fn exp, acc ->
      cost = exp.estimated_cost
      %{
        compute: acc.compute + Map.get(cost, :compute, 0),
        memory: acc.memory + Map.get(cost, :memory, 0),
        time_hours: acc.time_hours + Map.get(cost, :time_hours, 0),
        energy: acc.energy + Map.get(cost, :energy, 0)
      }
    end)
  end

  @spec validate(ExperimentPlan.t()) :: :ok | {:error, term()}
  def validate(%ExperimentPlan{} = plan) do
    cond do
      plan.hypothesis_id == nil -> {:error, :missing_hypothesis_id}
      plan.type == nil -> {:error, :missing_experiment_type}
      plan.success_criteria == nil or plan.success_criteria == [] -> {:error, :missing_success_criteria}
      plan.failure_criteria == nil or plan.failure_criteria == [] -> {:error, :missing_failure_criteria}
      plan.stopping_criteria == nil -> {:error, :missing_stopping_criteria}
      true -> :ok
    end
  end

  defp design_experiment(%HypothesisSpec{} = hypothesis, %PredictionSpec{} = prediction) do
    experiment_type = select_experiment_type(hypothesis, prediction)
    ExperimentPlan.new(%{
      hypothesis_id: hypothesis.id,
      prediction_ids: [prediction.id],
      type: experiment_type,
      inputs: build_inputs(hypothesis, prediction, experiment_type),
      outputs: build_outputs(hypothesis, prediction),
      variables: build_variables(hypothesis),
      controls: build_controls(hypothesis, experiment_type),
      stopping_criteria: build_stopping_criteria(hypothesis, prediction),
      success_criteria: build_success_criteria(prediction),
      failure_criteria: build_failure_criteria(prediction),
      estimated_cost: estimate_cost(experiment_type, hypothesis),
      expected_information_gain: (prediction.confidence || 0.5) * (hypothesis.expected_information_gain || 0.5)
    })
  end

  defp select_experiment_type(%HypothesisSpec{} = hypothesis, _prediction) do
    case Map.get(hypothesis.metadata, :causal_model) do
      :boundary_condition_divergence -> :controlled_simulation
      :measurement_divergence -> :observation
      :hidden_confound -> :controlled_simulation
      :temporal_evolution -> :historical_replay
      :sample_size_deficit -> :data_mining
      :collection_bias -> :observation
      :knowledge_supersession -> :data_mining
      :validation_deficit -> :controlled_simulation
      :scope_evolution -> :data_mining
      :recording_gap -> :data_mining
      :legacy_artifact -> :data_mining
      :direct_causation -> :controlled_simulation
      :analogical_transfer -> :data_mining
      :emergence -> :controlled_simulation
      :statistical_noise -> :data_mining
      _ -> :controlled_simulation
    end
  end

  defp build_inputs(hypothesis, prediction, experiment_type) do
    base = %{
      hypothesis_statement: hypothesis.statement || hypothesis.description,
      prediction_statement: prediction.statement || prediction.description,
      domain: hypothesis.domain,
      prior: hypothesis.prior
    }
    case experiment_type do
      :controlled_simulation ->
        Map.merge(base, %{simulation_parameters: %{iterations: 1000, confidence_threshold: 0.95,
          random_seed: :crypto.strong_rand_bytes(4) |> :binary.decode_unsigned()}})
      :observation ->
        Map.merge(base, %{observation_protocol: :systematic, sample_size: 100, duration_hours: 24})
      :historical_replay ->
        Map.merge(base, %{replay_range: :full_history, comparison_baseline: :current_state})
      :data_mining ->
        Map.merge(base, %{data_sources: [:unified_world_model, :executive_memory],
          query_scope: hypothesis.domain, min_records: 50})
      _ -> base
    end
  end

  defp build_outputs(_hypothesis, _prediction) do
    [
      %{name: :evidence, type: :list, description: "Collected evidence items"},
      %{name: :confidence_delta, type: :float, description: "Change in hypothesis confidence"},
      %{name: :posterior, type: :float, description: "Updated hypothesis confidence"},
      %{name: :prediction_confirmed, type: :boolean, description: "Whether prediction was confirmed"},
      %{name: :falsification_result, type: :string, description: "Result of falsification criteria check"}
    ]
  end

  defp build_variables(hypothesis) do
    stmt = hypothesis.statement || hypothesis.description
    [%{name: :independent_variable, description: "The factor being tested: #{stmt}"},
     %{name: :dependent_variable, description: "The outcome being measured"},
     %{name: :confidence, description: "Hypothesis confidence (0.0 to 1.0)"}]
  end

  defp build_controls(hypothesis, experiment_type) do
    base = [%{name: :null_hypothesis, description: "No effect / statistical fluctuation"},
            %{name: :baseline_measurement, description: "Measurement before intervention"}]
    case experiment_type do
      :controlled_simulation -> base ++ [%{name: :parameter_sweep, description: "Vary simulation parameters to test robustness"}]
      :observation -> base ++ [%{name: :independent_observer, description: "Second observer using different methodology"}]
      _ -> base
    end
  end

  defp build_stopping_criteria(_hypothesis, prediction) do
    %{max_iterations: 1000, max_duration_hours: 72, confidence_threshold: 0.95,
      falsification_met: "Stop if falsification criteria are met: #{prediction.falsification_criteria || "N/A"}",
      resource_exhaustion: "Stop if resource budget exceeded"}
  end

  defp build_success_criteria(prediction) do
    [ "Prediction confirmed: #{prediction.statement || prediction.description}",
      "Confidence in hypothesis increases by at least 0.1",
      "Falsification criteria NOT met: #{prediction.falsification_criteria || "N/A"}",
      "At least 3 independent evidence items collected" ]
  end

  defp build_failure_criteria(prediction) do
    [ "Falsification criteria met: #{prediction.falsification_criteria || "N/A"}",
      "Confidence in hypothesis decreases by more than 0.2",
      "No evidence collected after maximum iterations",
      "Resource budget exceeded without conclusive results" ]
  end

  defp estimate_cost(experiment_type, hypothesis) do
    base = case experiment_type do
      :controlled_simulation -> %{compute: 200, memory: 500, time_hours: 4, energy: 20}
      :observation -> %{compute: 50, memory: 100, time_hours: 24, energy: 5}
      :historical_replay -> %{compute: 100, memory: 300, time_hours: 2, energy: 10}
      :data_mining -> %{compute: 150, memory: 400, time_hours: 1, energy: 15}
      _ -> %{compute: 100, memory: 200, time_hours: 8, energy: 10}
    end
    risk_multiplier = 1.0 + (hypothesis.risk || 0.0)
    Map.new(base, fn {k, v} -> {k, round(v * risk_multiplier)} end)
  end
end
