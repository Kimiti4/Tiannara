defmodule ObservationBus.TiannaraBridge do
  use GenServer
  require Logger

  @cache_ttl_ms 5_000
  @failure_threshold 3
  @open_cooldown_ms 15_000
  @http_timeout_ms 4_000

  def start_link(opts \\ []), do: GenServer.start_link(__MODULE__, opts, name: __MODULE__)

  def fetch(key, opts \\ []), do: GenServer.call(__MODULE__, {:fetch, key, opts}, 10_000)

  def connection_status, do: GenServer.call(__MODULE__, :connection_status)

  def runtime_status,        do: fetch(:runtime_status)
  def campaign_phases,       do: fetch(:campaign_phases)
  def feedback_loop,         do: fetch(:feedback_loop)
  def asc_status,            do: fetch(:asc_status)
  def civilization_plan,     do: fetch(:civilization_plan)
  def civilization_decisions,do: fetch(:civilization_decisions)
  def civilization_metrics,  do: fetch(:civilization_metrics)
  def civilization_state,    do: fetch(:civilization_state)
  def global_risk,           do: fetch(:global_risk)
  def sustainability,        do: fetch(:sustainability)
  def campaign_telemetry,    do: fetch(:campaign_telemetry)

  defp spec(:runtime_status),
    do: %{mfa: {Tiannara.ControlCenter, :status, []}, http: "/api/v1/runtime/status"}
  defp spec(:campaign_phases),
    do: %{mfa: {Tiannara.Operations.CampaignScheduler, :phase_states, []}, http: "/api/v1/campaign/phases"}
  defp spec(:feedback_loop),
    do: %{mfa: {__MODULE__, :_feedback_loop, []}, http: "/api/v1/feedback/loop"}
  defp spec(:asc_status),
    do: %{mfa: {Tiannara.ASC.Core.Registry, :health_report, []}, http: "/api/v1/asc/status"}
  defp spec(:civilization_plan),
    do: %{mfa: {Tiannara.ASC.Civilization.Director, :current_plan, []}, http: "/api/v1/civilization/plan"}
  defp spec(:civilization_decisions),
    do: %{mfa: {Tiannara.ASC.Civilization.Director, :decisions, []}, http: "/api/v1/civilization/decisions"}
  defp spec(:civilization_metrics),
    do: %{mfa: {Tiannara.ASC.Civilization.Metrics, :snapshot, []}, http: "/api/v1/civilization/metrics"}
  defp spec(:civilization_state),
    do: %{mfa: {Tiannara.ASC.Civilization.Queries, :state, []}, http: "/api/v1/civilizational/state"}
  defp spec(:global_risk),
    do: %{mfa: {Tiannara.ASC.Civilization.Queries, :global_risk, []}, http: "/api/v1/civilizational/risk"}
  defp spec(:sustainability),
    do: %{mfa: {Tiannara.ASC.Civilization.Queries, :sustainability, []}, http: "/api/v1/civilizational/sustainability"}
  defp spec(:campaign_telemetry),
    do: %{mfa: {Tiannara.Operations.CampaignTelemetry, :snapshot, []}, http: "/api/v1/campaign/telemetry"}

  @doc false
  def _feedback_loop do
    cycles =
      case Process.whereis(Tiannara.Operations.Phase5FeedbackListener) do
        nil -> 0
        _ -> Tiannara.Operations.Phase5FeedbackListener.cycles()
      end

    last =
      case Process.whereis(Tiannara.Operations.Phase5FeedbackListener) do
        nil -> nil
        _ ->
          case Tiannara.Operations.Phase5FeedbackListener.history() do
            [h | _] -> DateTime.to_iso8601(h.at)
            _ -> nil
          end
      end

    %{cycles: cycles, last_at: last, closed: cycles > 0}
  end

  @impl true
  def init(_opts) do
    Application.ensure_all_started(:inets)
    {:ok, %{cache: %{}, circuit: :closed, failures: 0, opened_at: nil, mode: nil}}
  end

  @impl true
  def handle_call({:fetch, key, _opts}, _from, state) do
    state = %{state | mode: state.mode || detect_mode()}

    case cache_hit(key, state) do
      {:hit, value} ->
        {:reply, {:ok, value, :fresh}, state}

      :miss ->
        if circuit_open?(state) do
          case cache_stale(key, state) do
            {:stale, value} -> {:reply, {:ok, value, :stale}, state}
            :none -> {:reply, {:error, :circuit_open}, state}
          end
        else
          {reply, state} = do_remote(key, state)
          {:reply, reply, state}
        end
    end
  end

  @impl true
  def handle_call(:connection_status, _from, state) do
    state = %{state | mode: state.mode || detect_mode()}

    status = cond do
      circuit_open?(state) -> :disconnected
      state.circuit == :half_open -> :degraded
      state.failures > 0 -> :degraded
      true -> :connected
    end

    {:reply, %{status: status, mode: state.mode, failures: state.failures}, state}
  end

  @impl true
  def handle_info(_, state), do: {:noreply, state}

  defp do_remote(key, state) do
    %{mfa: mfa, http: path} = spec(key)
    started = System.monotonic_time(:millisecond)

    result = case state.mode do
      :direct -> call_direct(mfa)
      :rpc    -> call_rpc(mfa)
      :http   -> call_http(path)
    end

    latency = System.monotonic_time(:millisecond) - started

    :telemetry.execute(
      [:observatory, :bridge, :query],
      %{latency_ms: latency},
      %{key: key, mode: state.mode, ok: match?({:ok, _}, result)}
    )

    case result do
      {:ok, value} ->
        state = state |> put_cache(key, value) |> record_success()
        {{:ok, value, :fresh}, state}

      {:error, reason} ->
        Logger.debug("TiannaraBridge: #{key} failed (#{inspect(reason)})")
        state = record_failure(state)

        case cache_stale(key, state) do
          {:stale, value} -> {{:ok, value, :stale}, state}
          :none -> {{:error, reason}, state}
        end
    end
  end

  defp call_direct({m, f, a}) do
    if Code.ensure_loaded?(m) and function_exported?(m, f, length(a)) do
      {:ok, apply(m, f, a)}
    else
      {:error, {:not_exported, m, f}}
    end
  rescue
    e -> {:error, e}
  end

  defp call_rpc({m, f, a}) do
    case rpc_node() do
      nil -> {:error, :no_node_configured}
      node ->
        case :rpc.call(node, m, f, a, @http_timeout_ms) do
          {:badrpc, reason} -> {:error, {:badrpc, reason}}
          result -> {:ok, result}
        end
    end
  end

  defp call_http(path) do
    url = to_charlist(base_url() <> path)
    request = {url, [{~c"accept", ~c"application/json"}]}
    http_opts = [timeout: @http_timeout_ms, connect_timeout: @http_timeout_ms]

    case :httpc.request(:get, request, http_opts, []) do
      {:ok, {{_, code, _}, _hdrs, body}} when code in 200..299 ->
        decode_json(body)
      {:ok, {{_, code, _}, _, _}} ->
        {:error, {:http_status, code}}
      {:error, reason} ->
        {:error, reason}
    end
  end

  defp decode_json(body) do
    case Jason.decode(IO.iodata_to_binary(body)) do
      {:ok, value} -> {:ok, value}
      {:error, e} -> {:error, {:decode, e}}
    end
  end

  defp detect_mode do
    case Application.get_env(:observation_bus, :tiannara_bridge, []) |> Keyword.get(:mode, :auto) do
      :auto ->
        cond do
          Code.ensure_loaded?(Tiannara.ControlCenter) and Process.whereis(Tiannara.ControlCenter) != nil -> :direct
          rpc_node() != nil -> :rpc
          true -> :http
        end
      mode -> mode
    end
  end

  defp rpc_node, do: Application.get_env(:observation_bus, :tiannara_bridge, []) |> Keyword.get(:node)
  defp base_url, do: Application.get_env(:observation_bus, :tiannara_bridge, []) |> Keyword.get(:url, "http://localhost:4000")

  defp cache_hit(key, state) do
    case Map.get(state.cache, key) do
      %{value: value, at: at} -> if now() - at <= @cache_ttl_ms, do: {:hit, value}, else: :miss
      _ -> :miss
    end
  end

  defp cache_stale(key, state) do
    case Map.get(state.cache, key) do
      %{value: value} -> {:stale, value}
      _ -> :none
    end
  end

  defp put_cache(state, key, value) do
    %{state | cache: Map.put(state.cache, key, %{value: value, at: now()})}
  end

  defp circuit_open?(%{circuit: :open, opened_at: opened_at}) do
    if now() - opened_at >= @open_cooldown_ms, do: false, else: true
  end
  defp circuit_open?(_), do: false

  defp record_success(state) do
    %{state | circuit: :closed, failures: 0, opened_at: nil}
  end

  defp record_failure(state) do
    failures = state.failures + 1

    if failures >= @failure_threshold do
      if state.circuit != :open do
        Logger.warning("TiannaraBridge: circuit OPEN after #{failures} failures")
      end
      %{state | circuit: :open, failures: failures, opened_at: now()}
    else
      %{state | circuit: :half_open, failures: failures}
    end
  end

  defp now, do: System.monotonic_time(:millisecond)
end
