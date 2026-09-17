defmodule TiannaraRuntime.WorldModel.Prediction.ForecastGenerator do
  @moduledoc """
  Phase 17.4.2 — ForecastGenerator: simulates a world model's equation system forward
  to produce a Forecast. Supports constant and linear equation forms.
  """
  @behaviour TiannaraRuntime.WorldModel.Prediction.Behaviours.ForecastBehaviour

  alias TiannaraRuntime.WorldModel.Ontology.{WorldModel, EquationSystem, Equation, Parameter}
  alias TiannaraRuntime.WorldModel.Prediction.{Forecast, ForecastStep, ForecastVariable}

  @doc """
  Generate a forecast from a world model for the given target variables and horizon.
  """
  @impl true
  @spec generate(WorldModel.t(), [ForecastVariable.t()], atom(), keyword()) ::
    {:ok, Forecast.t()} | {:error, String.t()}
  def generate(nil, _target_variables, _horizon, _opts) do
    {:error, "World model is nil"}
  end

  def generate(%WorldModel{} = world_model, target_variables, horizon, opts \\ []) do
    with :ok <- validate_world_model(world_model),
         {:ok, steps} <- build_time_steps(world_model, target_variables, horizon, opts) do
      forecast = %Forecast{
        horizon: horizon,
        time_steps: steps,
        variables: target_variables,
        governing_equations: extract_governing_equations(world_model, target_variables),
        causal_constraints: extract_causal_constraints(world_model, target_variables),
        metadata: Keyword.get(opts, :metadata, %{})
      }

      {:ok, ensure_id(forecast)}
    end
  end

  @doc """
  Generate a trajectory (series of values) for a single variable over N steps.
  """
  @spec generate_trajectory(WorldModel.t(), String.t(), integer(), keyword()) ::
    {:ok, [ForecastStep.t()]} | {:error, String.t()}
  def generate_trajectory(%WorldModel{} = world_model, variable_name, num_steps, opts \\ []) do
    horizon = Keyword.get(opts, :horizon, :short_term)
    fv = build_forecast_variable(variable_name, world_model)

    with {:ok, steps} <- build_time_steps(world_model, [fv], horizon, [{:num_steps, num_steps} | opts]) do
      {:ok, steps}
    end
  end

  @doc """
  Find equilibrium value for a single variable by iterating until convergence.
  """
  @spec generate_equilibrium(WorldModel.t(), String.t(), keyword()) ::
    {:ok, float()} | {:error, String.t()}
  def generate_equilibrium(%WorldModel{} = world_model, variable_name, opts \\ []) do
    max_iters = Keyword.get(opts, :max_iterations, 1000)
    tolerance = Keyword.get(opts, :tolerance, 1.0e-8)

    fv = build_forecast_variable(variable_name, world_model)
    horizon = :short_term

    with {:ok, _initial_steps} <- build_time_steps(world_model, [fv], horizon, num_steps: 10),
         {:ok, value} <- converge_variable(world_model, variable_name, max_iters, tolerance) do
      {:ok, value}
    end
  end

  defp validate_world_model(%WorldModel{equations: nil}) do
    {:error, "WorldModel has no equation system"}
  end

  defp validate_world_model(%WorldModel{parameters: params}) when params == [] do
    {:error, "WorldModel has no parameters"}
  end

  defp validate_world_model(%WorldModel{status: status}) when status != :operational do
    {:error, "WorldModel is not in operational status"}
  end

  defp validate_world_model(%WorldModel{}), do: :ok

  defp build_time_steps(world_model, target_variables, horizon, opts) do
    num_steps = Keyword.get(opts, :num_steps, horizon_steps(horizon))
    param_map = build_param_map(world_model)
    state = initial_state(world_model)

    target_var_names = MapSet.new(target_variables, fn %ForecastVariable{name: n} -> n end)

    equations = get_target_equations(world_model, target_var_names)
    eq_order = topological_sort(equations, get_parent_map(equations))

    {:ok, simulate(eq_order, param_map, state, num_steps, target_var_names, world_model)}
  end

  defp horizon_steps(:immediate), do: 1
  defp horizon_steps(:short_term), do: 10
  defp horizon_steps(:medium_term), do: 50
  defp horizon_steps(:long_term), do: 100
  defp horizon_steps(:civilization), do: 500
  defp horizon_steps(_), do: 10

  defp get_target_equations(%WorldModel{equations: %EquationSystem{equations: eqs}}, target_var_names) do
    Enum.filter(eqs, fn %Equation{target_variable: tv} ->
      MapSet.member?(target_var_names, tv)
    end)
  end

  defp get_parent_map(equations) do
    Enum.reduce(equations, %{}, fn %Equation{target_variable: tv, expression: expr}, acc ->
      parents = Map.get(expr, "parents", Map.get(expr, :parents, []))
      Map.put(acc, tv, parents)
    end)
  end

  defp topological_sort(equations, parent_map) do
    eq_map = Map.new(equations, fn %Equation{target_variable: tv} = eq -> {tv, eq} end)
    all_vars = MapSet.new(Map.keys(eq_map))

    adj = parent_map

    in_degree =
      Map.new(all_vars, fn v ->
        parents = Map.get(adj, v, [])
        deps = Enum.filter(parents, fn p -> Map.has_key?(eq_map, p) end)
        {v, length(deps)}
      end)

    queue = Enum.filter(all_vars, fn v -> Map.get(in_degree, v, 0) == 0 end) |> Enum.reverse()
    sorted = do_sort(queue, in_degree, adj, eq_map, [])
    Enum.map(Enum.reverse(sorted), fn v -> Map.get(eq_map, v) end) |> Enum.reject(&is_nil/1)
  end

  defp do_sort([], _in_degree, _adj, _eq_map, sorted), do: sorted

  defp do_sort([v | rest], in_degree, adj, eq_map, sorted) do
    new_in_degree =
      Map.get(adj, v, [])
      |> Enum.reduce(in_degree, fn child, acc ->
        Map.update(acc, child, 0, &(&1 - 1))
      end)

    ready =
      Map.get(adj, v, [])
      |> Enum.filter(fn child -> Map.get(new_in_degree, child, 0) == 0 end)

    do_sort(rest ++ ready, new_in_degree, adj, eq_map, [v | sorted])
  end

  defp build_param_map(%WorldModel{parameters: params}) do
    Enum.reduce(params, %{}, fn %Parameter{name: pname, value: value, estimated_from: target}, acc ->
      Map.update(acc, target, %{pname => value}, fn existing -> Map.put(existing, pname, value) end)
    end)
  end

  defp initial_state(%WorldModel{state_space: ss, variables: vars}) do
    defaults = Map.get(ss, :default_initial, %{})
    var_names = Map.get(ss, :variable_order, Enum.map(vars, & &1.variable_id))

    Map.new(var_names, fn vname ->
      {vname, Map.get(defaults, vname, 0.0)}
    end)
  end

  defp simulate(_eq_order, _param_map, _state, 0, _target_vars, _wm), do: []

  defp simulate(eq_order, param_map, state, n, target_vars, wm) do
    new_state = evaluate_equations(eq_order, param_map, state)

    step_values =
      Map.take(new_state, MapSet.to_list(target_vars))

    {:ok, step_struct} = ForecastStep.new(
      step: n,
      timestamp: DateTime.utc_now() |> DateTime.to_iso8601(),
      values: step_values
    )

    [step_struct | simulate(eq_order, param_map, new_state, n - 1, target_vars, wm)]
  end

  defp evaluate_equations([], _param_map, state), do: state

  defp evaluate_equations([%Equation{target_variable: tv, expression: expr} | rest], param_map, state) do
    form = Map.get(expr, "form", Map.get(expr, :form))

    value =
      case form do
        "constant" -> evaluate_constant(tv, param_map)
        "linear" -> evaluate_linear(expr, param_map, state)
        _ -> Map.get(state, tv, 0.0)
      end

    evaluate_equations(rest, param_map, Map.put(state, tv, value))
  end

  defp evaluate_constant(tv, param_map) do
    case get_param(param_map, tv, "baseline") do
      {:ok, val} -> val
      _ -> 0.0
    end
  end

  defp evaluate_linear(expr, param_map, state) do
    parents = Map.get(expr, "parents", Map.get(expr, :parents, []))
    intercept = get_param(param_map, Map.get(expr, "target"), "intercept") |> elem(1)

    parent_sum =
      Enum.reduce(parents, 0.0, fn parent, acc ->
        case get_param(param_map, Map.get(expr, "target"), "beta_#{parent}") do
          {:ok, beta} -> acc + beta * Map.get(state, parent, 0.0)
          _ -> acc
        end
      end)

    parent_sum + intercept
  end

  defp get_param(param_map, target, name) do
    case Map.get(param_map, target, %{}) |> Map.get(name) do
      nil -> {:error, :not_found}
      val -> {:ok, val}
    end
  end

  defp converge_variable(world_model, variable_name, max_iters, tolerance) do
    param_map = build_param_map(world_model)
    state0 = initial_state(world_model)

    equations = get_target_equations(world_model, MapSet.new([variable_name]))
    eq_order = topological_sort(equations, get_parent_map(equations))

    do_converge(eq_order, param_map, state0, variable_name, max_iters, tolerance, 0)
  end

  defp do_converge(eq_order, param_map, state, var, max_iters, tolerance, iter) when iter < max_iters do
    new_state = evaluate_equations(eq_order, param_map, state)
    new_val = Map.get(new_state, var, 0.0)
    old_val = Map.get(state, var, 0.0)

    if abs(new_val - old_val) < tolerance do
      {:ok, new_val}
    else
      do_converge(eq_order, param_map, new_state, var, max_iters, tolerance, iter + 1)
    end
  end

  defp do_converge(_eq_order, _param_map, state, var, _max_iters, _tolerance, _iter) do
    {:ok, Map.get(state, var, 0.0)}
  end

  defp ensure_id(%Forecast{forecast_id: nil} = f), do: %{f | forecast_id: Forecast.compute_id(f)}
  defp ensure_id(%Forecast{} = f), do: f

  defp extract_governing_equations(%WorldModel{equations: %EquationSystem{equations: eqs}}, target_vars) do
    target_ids = MapSet.new(target_vars, fn %ForecastVariable{name: n} -> n end)

    eqs
    |> Enum.filter(fn %Equation{target_variable: tv} -> MapSet.member?(target_ids, tv) end)
    |> Enum.map(fn %Equation{equation_id: eid} -> eid end)
  end

  defp extract_causal_constraints(world_model, target_vars) do
    case world_model.causal_graph do
      nil -> []
      %{edges: edges} ->
        target_ids = MapSet.new(target_vars, fn %ForecastVariable{name: n} -> n end)

        edges
        |> Enum.filter(fn e -> MapSet.member?(target_ids, e.source) or MapSet.member?(target_ids, e.target) end)
        |> Enum.map(fn e -> e.edge_id end)
    end
  end

  defp build_forecast_variable(variable_name, %WorldModel{variables: vars}) do
    case Enum.find(vars, fn v -> v.name == variable_name or v.variable_id == variable_name end) do
      nil -> %ForecastVariable{name: variable_name}
      v -> %ForecastVariable{name: v.name, type: map_var_type(v.type)}
    end
  end

  defp map_var_type(:continuous), do: :continuous
  defp map_var_type(:discrete), do: :continuous
  defp map_var_type(:categorical), do: :categorical
  defp map_var_type(_), do: :continuous
end
