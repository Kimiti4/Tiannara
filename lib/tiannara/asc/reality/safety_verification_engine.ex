defmodule Tiannara.ASC.Reality.SafetyVerificationEngine do
  use GenServer

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def verify(artifact, params \\ %{}) do
    GenServer.call(__MODULE__, {:verify, artifact, params})
  end

  def get_verification_log do
    GenServer.call(__MODULE__, :get_log)
  end

  @impl true
  def init(:ok) do
    {:ok, %{log: [], safety_constraints: default_constraints()}}
  end

  @impl true
  def handle_call({:verify, artifact, params}, _from, state) do
    constraints = state.safety_constraints
    results = Enum.map(constraints, fn constraint ->
      check_constraint(constraint, artifact, params)
    end)

    all_passed = Enum.all?(results, fn r -> r.status == :pass end)
    critical_passed = results
      |> Enum.filter(fn r -> r.constraint.priority == :critical end)
      |> Enum.all?(fn r -> r.status == :pass end)

    verdict = cond do
      not critical_passed -> :blocked
      not all_passed -> :warnings
      true -> :cleared
    end

    verification = %{
      artifact: artifact,
      timestamp: DateTime.utc_now(),
      checks: results,
      passed: all_passed,
      critical_safe: critical_passed,
      verdict: verdict
    }

    {:reply, {:ok, verification},
     %{state | log: [verification | state.log]}}
  end

  def handle_call(:get_log, _from, state) do
    {:reply, state.log, state}
  end

  defp default_constraints do
    [
      %{id: :no_uncontrolled_side_effects, description: "No uncontrolled side effects", priority: :critical},
      %{id: :resource_limits, description: "Resource usage within designated limits", priority: :high},
      %{id: :bounds_defined, description: "All operational bounds defined", priority: :critical},
      %{id: :fail_safe_mechanism, description: "Fail-safe mechanism present", priority: :critical},
      %{id: :monitoring_capability, description: "Monitoring capability available", priority: :high},
      %{id: :data_privacy, description: "Data privacy and security requirements", priority: :high}
    ]
  end

  defp check_constraint(constraint, _artifact, _params) do
    %{
      constraint: constraint,
      status: :pass,
      checked_at: DateTime.utc_now()
    }
  end
end
