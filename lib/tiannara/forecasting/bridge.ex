defmodule Tiannara.Forecasting.Bridge do
  @moduledoc """
  The canonical cross-stack boundary to EFDI.

  EFDI is owned by the application stack. The Cognitive Execution Spine lives
  in the runtime stack. The two OTP applications have **no compile-time
  dependency on each other** — and cannot have one yet, because 28 module
  names are defined in both stacks and merging them would redefine modules.
  That consolidation is TCP-002's W1 work, not TCP-002.3's.

  This module is therefore the *contract* half of the boundary, expressed as a
  versioned, JSON-safe request/response pair. It is deliberately transport
  agnostic: `handle_request/1` takes a decoded map and returns a decoded map,
  so it can be served over NATS, HTTP, or any future transport without
  changing the contract.

  ## Why an explicit wire format

  `Contracts.Forecast` is a struct containing atoms such as `:unknown`, tuples
  and `DateTime` values. Those cannot be transmitted faithfully, and a struct
  dumped across a boundary is an untrusted term. The wire format below is
  explicit, versioned, and JSON-safe in both directions.

  ## Request (schema version 1)

      %{
        "v" => 1,
        "request_id" => "req_...",
        "question" => "Will the thermal model converge?",
        "event" => "model_converged",
        "outcomes" => ["yes", "no"],
        "horizon" => "24h",
        "evidence" => [
          %{"id" => "ev_1", "epistemic_status" => "observed",
            "source" => "sensor_a", "observed_at" => "2026-06-01T12:00:00Z"}
        ],
        "signal_ids" => [],
        "base_rate" => %{"historical_frequency" => 0.62} | nil,
        "model_ref" => "model_v3" | nil,
        "assumptions" => [],
        "context" => %{},
        "regime" => "stable" | nil,
        "provenance" => %{"origin" => "cognitive_execution_spine",
                          "investigation_id" => "...", "requested_by" => "..."}
      }

  ## Response (schema version 1)

      %{"v" => 1, "request_id" => "...", "status" => "ok" | "error",
        "forecast" => %{...} | nil, "error" => %{"reason" => "...", "message" => "..."} | nil}

  ## Constitutional rules

    * EFDI predicts. It does not decide and it does not authorize. A forecast
      produced here is never a mandate.
    * A missing outcome contract is an error, not a default.
    * A missing base rate yields `:unknown` probabilities inside EFDI; it is
      never replaced with an invented value at this boundary.
    * Simulated evidence is accepted but is carried through as simulated.
  """
  use GenServer

  alias Tiannara.Forecasting.BaseRateEngine
  alias Tiannara.Forecasting.Contracts
  alias Tiannara.Forecasting.ForecastRegistry

  @schema_version 1

  @epistemic_statuses ~w(observed verified inferred simulated hypothetical unknown rejected)

  @request_fields ~w(v request_id question event outcomes horizon evidence
                     signal_ids base_rate model_ref assumptions context regime provenance)

  @response_fields ~w(v request_id status forecast error)

  @doc "The wire schema version this bridge speaks."
  @spec schema_version() :: pos_integer()
  def schema_version, do: @schema_version

  @doc "The required request fields, for contract conformance tests."
  @spec request_fields() :: [String.t()]
  def request_fields, do: @request_fields

  @doc "The response fields, for contract conformance tests."
  @spec response_fields() :: [String.t()]
  def response_fields, do: @response_fields

  @doc "The epistemic statuses this boundary accepts for evidence."
  @spec epistemic_statuses() :: [String.t()]
  def epistemic_statuses, do: @epistemic_statuses

  def start_link(opts \\ []), do: GenServer.start_link(__MODULE__, opts, name: __MODULE__)

  @impl true
  def init(_opts), do: {:ok, %{}}

  @doc """
  Handles a decoded forecast request and returns a decoded response.

  Always returns a response map. The failure reason is carried inside it, so
  a transport never has to interpret an exception.
  """
  @spec handle_request(map()) :: map()
  def handle_request(payload) when is_map(payload) do
    with {:ok, request} <- validate(payload),
         {:ok, forecast} <- forecast_or_replay(request) do
      %{
        "v" => @schema_version,
        "request_id" => request["request_id"],
        "status" => "ok",
        "forecast" => to_wire_forecast(forecast),
        "error" => nil
      }
    else
      {:error, reason} ->
        %{
          "v" => @schema_version,
          "request_id" => Map.get(payload, "request_id") || Map.get(payload, :request_id),
          "status" => "error",
          "forecast" => nil,
          "error" => %{"reason" => to_reason_string(reason), "message" => reason_message(reason)}
        }
    end
  end

  def handle_request(_payload) do
    handle_request_error(:invalid_request_payload, nil)
  end

  @doc """
  Produces a forecast through the canonical EFDI API and registers it.

  Registration is what makes the forecast durable and immutable: the registry
  refuses to overwrite an existing id, so a repeated request returns the
  original forecast rather than a rewritten one.
  """
  @spec forecast(map()) :: {:ok, Contracts.Forecast.t()} | {:error, term()}
  def forecast(request) when is_map(request) do
    request_id = request["request_id"]
    fingerprint = request_fingerprint(request)

    # Idempotency: a repeated request returns the original forecast rather
    # than creating a second one.
    with :ok <- check_request_id(request_id),
         :ok <- check_no_conflict(request_id, fingerprint),
         {:ok, forecast} <- Tiannara.Forecasting.forecast(to_forecast_request(request)),
         {:ok, stored} <-
           Tiannara.Forecasting.register_forecast(forecast,
             request_id: request_id,
             request_fingerprint: fingerprint
           ) do
      {:ok, stored}
    else
      {:error, reason} -> {:error, reason}
    end
  catch
    # The registry is a separate process. If it is not running, the forecast
    # cannot be registered and the caller must be told so explicitly rather
    # than crashing.
    :exit, _reason -> {:error, :forecast_registry_unavailable}
  end

  @doc "The forecast previously produced for `request_id`, if any."
  @spec forecast_for_request(String.t()) :: {:ok, Contracts.Forecast.t()} | :error
  def forecast_for_request(request_id) when is_binary(request_id) do
    case ForecastRegistry.request_index()[request_id] do
      nil -> :error
      %{forecast_id: forecast_id} -> ForecastRegistry.get(forecast_id)
    end
  catch
    :exit, _ -> :error
  end

  # A request id identifies a specific forecast request. If the same id
  # arrives carrying different content, replaying the earlier forecast would
  # silently answer a different question, so the conflict is refused.
  defp check_no_conflict(request_id, fingerprint) do
    case ForecastRegistry.request_index()[request_id] do
      nil ->
        :ok

      %{fingerprint: ^fingerprint} ->
        :ok

      %{fingerprint: other} ->
        if is_nil(other) do
          :ok
        else
          {:error, :request_id_conflict}
        end

      _ ->
        :ok
    end
  catch
    :exit, _ -> :ok
  end

  # The fingerprint covers the decision-time content of the request, not its
  # correlation id.
  defp request_fingerprint(request) do
    content =
      request
      |> Map.delete("request_id")
      |> :erlang.term_to_binary()

    :crypto.hash(:sha256, content) |> Base.encode16(case: :lower)
  end

  # A repeated request id must return the original forecast. A repeated id
  # carrying *different* content is refused rather than replayed.
  defp forecast_or_replay(request) do
    with :ok <- check_no_conflict(request["request_id"], request_fingerprint(request)) do
      case forecast_for_request(request["request_id"]) do
        {:ok, forecast} -> {:ok, forecast}
        :error -> forecast(request)
      end
    end
  end

  defp check_request_id(request_id) when is_binary(request_id) and request_id != "", do: :ok
  defp check_request_id(_), do: {:error, :missing_request_id}

  # ------------------------------------------------------------- validation

  defp validate(payload) do
    with :ok <- validate_version(payload),
         {:ok, request_id} <- require_binary(payload, "request_id"),
         {:ok, question} <- require_binary(payload, "question"),
         {:ok, outcomes} <- require_binary_list(payload, "outcomes"),
         {:ok, horizon} <- require_binary(payload, "horizon"),
         {:ok, evidence} <- validate_evidence(payload),
         :ok <- validate_provenance(payload) do
      {:ok,
       %{
         "request_id" => request_id,
         "question" => question,
         "event" => Map.get(payload, "event") || question,
         "outcomes" => outcomes,
         "horizon" => horizon,
         "evidence" => evidence,
         "signal_ids" => Map.get(payload, "signal_ids") || [],
         "base_rate" => Map.get(payload, "base_rate"),
         "model_ref" => Map.get(payload, "model_ref"),
         "assumptions" => Map.get(payload, "assumptions") || [],
         "context" => Map.get(payload, "context") || %{},
         "regime" => Map.get(payload, "regime"),
         "provenance" => Map.get(payload, "provenance") || %{}
       }}
    end
  end

  defp validate_version(payload) do
    case Map.get(payload, "v") do
      nil -> {:error, :missing_schema_version}
      @schema_version -> :ok
      _ -> {:error, :unsupported_schema_version}
    end
  end

  defp require_binary(payload, key) do
    case Map.get(payload, key) do
      value when is_binary(value) and value != "" -> {:ok, value}
      _ -> {:error, :"missing_#{key}"}
    end
  end

  defp require_binary_list(payload, key) do
    case Map.get(payload, key) do
      values when is_list(values) and values != [] ->
        if Enum.all?(values, &(is_binary(&1) and &1 != "")) do
          {:ok, values}
        else
          {:error, :"invalid_#{key}"}
        end

      _ ->
        {:error, :"missing_#{key}"}
    end
  end

  defp validate_evidence(payload) do
    case Map.get(payload, "evidence") do
      entries when is_list(entries) and entries != [] ->
        Enum.reduce_while(entries, {:ok, []}, fn entry, {:ok, acc} ->
          with {:ok, id} <- require_binary(entry, "id"),
               {:ok, status} <- require_binary(entry, "epistemic_status"),
               :ok <- validate_epistemic_status(status) do
            {:cont, {:ok, acc ++ [Map.put(entry, "id", id)]}}
          else
            {:error, reason} -> {:halt, {:error, reason}}
          end
        end)

      _ ->
        {:error, :missing_evidence}
    end
  end

  defp validate_epistemic_status(status) do
    if status in @epistemic_statuses do
      :ok
    else
      {:error, :invalid_epistemic_status}
    end
  end

  defp validate_provenance(payload) do
    case Map.get(payload, "provenance") do
      provenance when is_map(provenance) ->
        case Map.get(provenance, "origin") do
          origin when is_binary(origin) and origin != "" -> :ok
          _ -> {:error, :missing_provenance}
        end

      _ ->
        {:error, :missing_provenance}
    end
  end

  # ------------------------------------------------------------- conversion

  defp to_forecast_request(request) do
    %Contracts.ForecastRequest{
      question: request["question"],
      event: request["event"],
      outcomes: request["outcomes"],
      horizon: request["horizon"],
      signal_ids: request["signal_ids"],
      evidence_ids: Enum.map(request["evidence"], & &1["id"]),
      base_rate: to_base_rate(request["base_rate"]),
      model: request["model_ref"],
      assumptions: request["assumptions"],
      context: request["context"],
      regime: request["regime"]
    }
  end

  # The wire format uses string keys; `Contracts.BaseRate` is a struct with
  # atom keys read by dot access. EFDI's own canonical constructor is reused
  # rather than re-implemented, so the bridge cannot drift from EFDI's
  # defaults (notably `:unknown` for an absent historical frequency).
  defp to_base_rate(nil), do: nil

  defp to_base_rate(%{} = base_rate) do
    BaseRateEngine.new(Map.new(base_rate, fn {k, v} -> {String.to_existing_atom(k), v} end))
  rescue
    ArgumentError -> nil
  end

  defp to_wire_forecast(forecast) do
    %{
      "id" => forecast.id,
      "question" => forecast.question,
      "event" => forecast.event,
      "outcomes" => forecast.outcomes,
      "horizon" => forecast.horizon,
      "probabilities" => wire_value(forecast.probabilities),
      "probability" => wire_value(forecast.probability),
      "distribution" => wire_value(forecast.distribution),
      "uncertainty" => wire_value(forecast.uncertainty),
      "confidence" => wire_value(forecast.confidence),
      "model_ref" => forecast.model_ref,
      "base_rate_ref" => wire_value(forecast.base_rate_ref),
      "evidence_refs" => forecast.evidence_refs || [],
      "signal_refs" => forecast.signal_refs || [],
      "assumptions" => forecast.assumptions || [],
      "unknowns" => forecast.unknowns || [],
      "lineage" => forecast.lineage || [],
      "context" => wire_value(forecast.context),
      "regime" => forecast.regime,
      "provenance" => wire_value(forecast.provenance),
      "forecast_version" => forecast.forecast_version,
      "created_at" => wire_timestamp(forecast.created_at),
      "epistemic_status" => "forecasted"
    }
  end

  # `:unknown` is a valid EFDI probability and must survive the boundary as
  # the string "unknown", distinct from the number 0.0.
  defp wire_value(:unknown), do: "unknown"
  defp wire_value(nil), do: nil
  defp wire_value(value) when is_atom(value), do: Atom.to_string(value)
  defp wire_value(%DateTime{} = value), do: DateTime.to_iso8601(value)
  defp wire_value(%NaiveDateTime{} = value), do: NaiveDateTime.to_iso8601(value)
  defp wire_value(%Date{} = value), do: Date.to_iso8601(value)
  # A struct is a map but does not implement Enumerable, so `Map.new/2` fails
  # on it. `Map.from_struct/1` removes the `:__struct__` key first.
  defp wire_value(%_{} = value), do: value |> Map.from_struct() |> wire_value()
  defp wire_value(%{} = value), do: Map.new(value, fn {k, v} -> {to_string(k), wire_value(v)} end)
  defp wire_value(value) when is_list(value), do: Enum.map(value, &wire_value/1)
  defp wire_value(value) when is_tuple(value), do: inspect(value)
  defp wire_value(value), do: value

  defp wire_timestamp(nil), do: nil
  defp wire_timestamp(%DateTime{} = value), do: DateTime.to_iso8601(value)
  defp wire_timestamp(%NaiveDateTime{} = value), do: NaiveDateTime.to_iso8601(value)
  defp wire_timestamp(value) when is_integer(value), do: value
  defp wire_timestamp(value), do: to_string(value)

  defp handle_request_error(reason, request_id) do
    %{
      "v" => @schema_version,
      "request_id" => request_id,
      "status" => "error",
      "forecast" => nil,
      "error" => %{"reason" => to_reason_string(reason), "message" => reason_message(reason)}
    }
  end

  defp to_reason_string(reason) when is_atom(reason), do: Atom.to_string(reason)
  defp to_reason_string(reason), do: inspect(reason)

  defp reason_message(reason) do
    case reason do
      :missing_schema_version -> "the request does not declare a schema version"
      :unsupported_schema_version -> "the request declares a schema version this bridge does not speak"
      :missing_request_id -> "a request id is required so the response can be correlated"
      :missing_question -> "a forecast question is required"
      :missing_outcomes -> "a forecast must declare its outcome space"
      :invalid_outcomes -> "every outcome must be a non-empty string"
      :missing_horizon -> "a forecast must declare its horizon"
      :missing_evidence -> "at least one piece of evidence is required"
      :missing_provenance -> "provenance with an origin is required"
      :invalid_epistemic_status -> "the epistemic status of the evidence is not recognised"
      :invalid_request_payload -> "the request payload is not a map"
      other -> "the forecast request was refused: #{inspect(other)}"
    end
  end
end
