defmodule Tiannara.Domains.Physics do
  @behaviour Tiannara.Domains.Domain

  alias Tiannara.Evidence.Provenance
  alias Tiannara.Foundations.Mathematics.Calculus
  alias Tiannara.Math.Probability

  @energy_tolerance 1.0e-6
  @producer "Tiannara.Domains.Physics"

  @impl true
  def discover(context), do: {:ok, %{domain: :physics, discoveries: [], context: context}}

  @impl true
  def evaluate(%{prior: p, likelihood: l, evidence: e}) do
    Probability.bayes_update(p, l, e)
  end

  @impl true
  def simulate(hypothesis, context) do
    equations = Map.get(hypothesis || %{}, :equations, [])
    boundary_conditions = Map.get(context || %{}, :boundary_conditions, [])
    time_span = Map.get(context || %{}, :time_span, 1.0)

    case Calculus.solve_ode(equations, boundary_conditions, time_span) do
      {:ok, result} ->
        with {:ok, prov} <- build_provenance(result) do
          {:ok, %{result: result, provenance: prov}}
        end

      {:error, _reason} = error ->
        error
    end
  end

  @impl true
  def generate_hypotheses(_context), do: {:ok, []}

  @impl true
  def design_experiments(_hypothesis), do: {:ok, []}

  @impl true
  def validate(experiment) do
    case experiment do
      %{model: %{result: %{trajectory: trajectory, params: params, initial_state: initial}}}
      when is_list(trajectory) and is_list(initial) ->
        structural_validation(trajectory, params, initial)

      _ ->
        {:error, :formal_verification_unavailable}
    end
  end

  @impl true
  def translate(_hypothesis), do: {:ok, %{engineering_applications: []}}

  @impl true
  def metrics do
    {:ok, %{discoveries: discoveries}} = discover(%{})
    %{
      active_hypotheses: 0,
      open_experiments: 0,
      discoveries_this_cycle: length(discoveries),
      knowledge_growth_rate: 0.0,
      evidence_quality_score: 0.0,
      hypotheses_generated: 0,
      experiments_completed: 0,
      metrics_source: :state_derived
    }
  end

  @doc """
  MC-004-P pilot experiment definition: a damped harmonic oscillator
  (`m x'' + c x' + k x = 0`, underdamped: c^2 < 4mk) encoded as a first-order
  system for the real RK4 solver. Used by the pilot gate and by the
  AutonomousDiscoveryEngine placeholder replacement (MU-4).
  """
  def pilot_experiment do
    m = 1.0
    k = 4.0
    c = 0.5
    x0 = 1.0
    v0 = 0.0

    derivative = fn _t, [x, v] -> [v, -c / m * v - k / m * x] end

    equations = %{
      type: :first_order_system,
      dimension: 2,
      derivative: derivative,
      params: %{m: m, c: c, k: k, model: :damped_harmonic_oscillator}
    }

    %{
      hypothesis: %{
        subject: :mechanics,
        object: :damped_oscillation,
        equations: equations,
        description: "MC-004-P damped harmonic oscillator (underdamped)"
      },
      context: %{boundary_conditions: [x0, v0], time_span: %{duration: 10.0, dt: 0.01}}
    }
  end

  @doc """
  MU-4 bridge: adapts a physics experiment spec into the gated Phase4
  real-execution gateway. While `:real_execution_enabled` is false this
  truthfully returns `{:error, :real_execution_not_enabled}`; no real execution
  is possible until MC-004-P enables the flag under separate authorization.
  """
  def execute_experiment(spec) do
    cond do
      Map.get(spec, :grant) && Tiannara.Phase4.RealExecution.enabled?() ->
        Tiannara.Phase4.PhysicsPilotExecution.execute(spec)

      true ->
        with {:ok, phase4_spec} <- to_phase4_spec(spec) do
          Tiannara.Phase4.ExperimentOrchestrator.submit_experiment(phase4_spec)
        end
    end
  end

  # --- provenance (MU-2) ---

  defp build_provenance(result) do
    Provenance.build(
      kind: :simulation,
      source: @producer,
      producer: @producer,
      environment: %{
        model_type: :ode_first_order_system,
        method: result.method,
        order: result.order,
        steps: result.steps,
        dt: result.dt
      },
      evidence_hash: config_hash(result)
    )
  end

  defp config_hash(result) do
    canonical =
      :erlang.term_to_binary(
        Map.take(result, [:params, :initial_state, :dt, :t_end])
      )

    :crypto.hash(:sha256, canonical) |> Base.encode16(case: :lower)
  end

  # --- structural verification (MU-2; NOT formal verification) ---

  defp structural_validation(trajectory, params, initial) do
    case params do
      %{m: m, c: c, k: k} = p when is_number(m) and is_number(c) and is_number(k) and m > 0 and k > 0 ->
        initial_energy = oscillator_energy(initial, p)

        checks =
          Enum.map(trajectory, fn %{x: [x, v]} = point ->
            e = oscillator_energy([x, v], p)
            %{
              check: :energy_bounded,
              t: point.t,
              energy: e,
              within_tolerance: e <= initial_energy * (1.0 + @energy_tolerance)
            }
          end)

        finite_points = Enum.all?(trajectory, fn %{x: xs} -> Enum.all?(xs, &finite_number?/1) end)
        valid = finite_points and Enum.all?(checks, & &1.within_tolerance)

        {:ok,
         %{
           valid: valid,
           value: finite_points,
           verification_method: :structural_checks,
           invariants: [:energy_bounded],
           checks: checks,
           provenance: %{kind: :simulation, producer: @producer, source: @producer, note: "structural verification of RK4 output"}
         }}

      _ ->
        {:error, :formal_verification_unavailable}
    end
  end

  defp oscillator_energy([x, v], %{m: m, k: k}), do: 0.5 * m * v * v + 0.5 * k * x * x

  defp finite_number?(value) do
    is_number(value) and value == value
  end

  # --- Phase4 bridge (MU-4) ---

  defp to_phase4_spec(%{hypothesis: hypothesis, context: _context} = spec) do
    if is_map(hypothesis) do
      {:ok,
       %{
         id: Map.get(spec, :id, "MC004P_#{:crypto.strong_rand_bytes(6) |> Base.encode16(case: :lower)}"),
         name: Map.get(spec, :name, "MC-004-P damped harmonic oscillator"),
         type: :simulation,
         hypotheses: [
           %{
             subject: Map.get(hypothesis, :subject),
             object: Map.get(hypothesis, :object),
             description: Map.get(hypothesis, :description)
           }
         ],
         workflow: nil
       }}
    else
      {:error, :invalid_experiment_spec}
    end
  end

  defp to_phase4_spec(_), do: {:error, :invalid_experiment_spec}
end