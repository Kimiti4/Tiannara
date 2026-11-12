defmodule TiannaraRuntime.Cognitive.Spine.Forecasting.Nats do
  @moduledoc """
  NATS transport for the Spine → EFDI forecasting boundary.

  NATS is the one inter-stack mechanism both applications already depend on:
  the runtime uses it for its phase supervisors, and the application stack has
  `:gnat` in its dependencies. The request/response pair is carried as JSON
  on a request subject and a correlated response subject.

  ## Guarantees

    * **Correlation** — every request carries a `request_id`; the response
      subject is derived from it, so a response can never satisfy the wrong
      request.
    * **Idempotency** — the request id is deterministic for a given
      investigation and forecast target, so a retried request returns the
      original forecast rather than creating a second one.
    * **Timeout** — a request that is not answered within the configured
      window fails closed with `{:error, :forecast_engine_timeout}`.
    * **Explicit unavailability** — a missing connection or an unreachable
      authority fails closed with `{:error, :forecast_engine_unavailable}`.
    * **No untrusted terms** — only JSON crosses the boundary.

  The transport is optional. With no EFDI boundary wired, the Spine uses
  `TiannaraRuntime.Cognitive.Spine.Forecasting.Refusing` and reports
  `{:error, :forecast_engine_unavailable}`.
  """
  @behaviour TiannaraRuntime.Cognitive.Spine.Forecasting

  require Logger

  @request_subject "tiannara.efdi.forecast.request"
  @response_prefix "tiannara.efdi.forecast.response"

  @impl true
  def forecast(request) when is_map(request) do
    request_id = Map.get(request, "request_id") || Map.get(request, :request_id)

    with {:ok, request_id} <- ensure_request_id(request_id),
         {:ok, payload} <- encode(request),
         {:ok, conn} <- connection() do
      case Gnat.request(conn, @request_subject, payload, %{})
      do
        {:ok, response} ->
          decode(response, request_id)

        {:error, :timeout} ->
          {:error, :forecast_engine_timeout}

        {:error, reason} ->
          Logger.warning("EFDI forecast request failed: #{inspect(reason)}")
          {:error, :forecast_engine_unavailable}
      end
    end
  end

  def forecast(_request), do: {:error, :invalid_request_payload}

  @doc "The NATS subject forecast requests are published on."
  @spec request_subject() :: String.t()
  def request_subject, do: @request_subject

  @doc "The NATS subject a forecast response for `request_id` arrives on."
  @spec response_subject(String.t()) :: String.t()
  def response_subject(request_id), do: @response_prefix <> "." <> request_id

  defp ensure_request_id(id) when is_binary(id) and id != "", do: {:ok, id}
  defp ensure_request_id(_), do: {:error, :missing_request_id}

  defp encode(request) do
    case Jason.encode(request) do
      {:ok, payload} -> {:ok, payload}
      {:error, reason} -> {:error, {:request_encoding_failed, reason}}
    end
  end

  defp decode(response, request_id) do
    case Jason.decode(response) do
      {:ok, %{"status" => "ok", "forecast" => forecast}} when is_map(forecast) ->
        {:ok, Map.put(forecast, "request_id", request_id)}

      {:ok, %{"status" => "error", "error" => error}} when is_map(error) ->
        {:error, Map.get(error, "reason") || :forecast_refused}

      {:ok, _other} ->
        {:error, :invalid_forecast_response}

      {:error, _reason} ->
        {:error, :invalid_forecast_response}
    end
  end

  defp connection do
    case Application.get_env(:tiannara_runtime, :nats_connection) do
      nil -> {:error, :forecast_engine_unavailable}
      name -> {:ok, name}
    end
  end
end
