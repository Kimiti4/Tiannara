defmodule Tiannara.MetaSOPL.RateModulationSupervisor do
  @moduledoc """
  META-SOPL supervisory boundary.

  MetaSOPL may propose bounded parameter adjustments to SOPL, but it must never
  self-authorize an adjustment. There is no autonomous/random modulation path:
  without an observed telemetry provider and an explicit authorization/validation
  result, the operation fails closed.
  """
  use Supervisor

  def start_link(init_arg) do
    Supervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  @impl true
  def init(init_arg) do
    children = [{Tiannara.MetaSOPL.Governor, init_arg}]
    Supervisor.init(children, strategy: :one_for_one)
  end
end

defmodule Tiannara.MetaSOPL.Governor do
  use GenServer
  use TiannaraRuntime.Layer, authority: :meta, can_call: [:constraint], can_receive: [:constraint]

  alias TiannaraRuntime.Contracts.MetaAdjustment

  @bounds %{
    mutation_rate: {0.01, 0.20},
    selection_pressure: {0.0, 1.0},
    entropy_target: {0.0, 1.0},
    exploration_temperature: {0.0, 1.0}
  }

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(opts) do
    {:ok, %{
      telemetry_provider: Keyword.get(opts, :telemetry_provider),
      authorizer: Keyword.get(opts, :authorizer),
      validator: Keyword.get(opts, :validator)
    }}
  end

  def propose do
    GenServer.call(__MODULE__, :propose)
  end

  @impl true
  def handle_call(:propose, _from, state) do
    with {:ok, telemetry} <- observed_telemetry(state.telemetry_provider),
         {:ok, adjustment} <- derive_adjustment(telemetry),
         :ok <- authorize(state.authorizer, telemetry, adjustment),
         :ok <- validate(state.validator, telemetry, adjustment),
         :ok <- emit(adjustment) do
      {:reply, {:ok, adjustment}, state}
    else
      {:error, reason} = error ->
        {:reply, error, state}
    end
  end

  defp observed_telemetry(provider) when is_function(provider, 0) do
    case provider.() do
      {:ok, telemetry} when is_map(telemetry) -> {:ok, telemetry}
      telemetry when is_map(telemetry) -> {:ok, telemetry}
      {:error, reason} -> {:error, {:telemetry_unavailable, reason}}
      other -> {:error, {:invalid_telemetry, other}}
    end
  end

  defp observed_telemetry(_), do: {:error, :meta_sopl_backend_unavailable}

  defp derive_adjustment(telemetry) do
    values = %{
      mutation_rate: Map.get(telemetry, :mutation_rate),
      selection_pressure: Map.get(telemetry, :selection_pressure),
      entropy_target: Map.get(telemetry, :entropy_target),
      exploration_temperature: Map.get(telemetry, :exploration_temperature)
    }

    if Enum.all?(values, fn {_k, v} -> is_number(v) end) and within_bounds?(values) do
      {:ok, struct!(MetaAdjustment, values)}
    else
      {:error, :invalid_or_out_of_bounds_meta_adjustment}
    end
  end

  defp authorize(provider, telemetry, adjustment) when is_function(provider, 2) do
    case provider.(telemetry, adjustment) do
      :ok -> :ok
      {:error, reason} -> {:error, {:meta_sopl_authorization_failed, reason}}
      other -> {:error, {:invalid_authorization_result, other}}
    end
  end

  defp authorize(_, _, _), do: {:error, :meta_sopl_authorizer_unavailable}

  defp validate(provider, telemetry, adjustment) when is_function(provider, 2) do
    case provider.(telemetry, adjustment) do
      :ok -> :ok
      {:error, reason} -> {:error, {:meta_sopl_validation_failed, reason}}
      other -> {:error, {:invalid_validation_result, other}}
    end
  end

  defp validate(_, _, _), do: {:error, :meta_sopl_validator_unavailable}

  defp emit(adjustment) do
    TiannaraRuntime.Layer.assert_call!(:meta, :constraint)
    case Process.whereis(TiannaraRuntime.Cortex.SafetyCortex) do
      nil -> {:error, :constraint_backend_unavailable}
      pid ->
        GenServer.cast(pid, {:meta_adjustment, adjustment})
        :ok
    end
  end

  defp within_bounds?(values) do
    Enum.all?(@bounds, fn {key, {min, max}} ->
      value = Map.fetch!(values, key)
      value >= min and value <= max
    end)
  end
end
