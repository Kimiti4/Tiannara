defmodule Tiannara.Research.Forecasting do
  @moduledoc """
  Adapter from the Research Director to the canonical forecasting authority.

  This module performs **no forecasting mathematics**. It builds a versioned
  request and hands it to `Tiannara.Forecasting.Bridge`, which invokes the
  canonical EFDI implementation. The forecasting authority remains EFDI; this
  is only the wiring.

  ## Where the forecast belongs

  The Research Director's pipeline is:

      priority → hypothesis → experiment plan → experiment

  A probabilistic forecast belongs at the **hypothesis evaluation stage**:
  once a hypothesis exists, its proposition, its outcome space and its
  resolution criteria define what can be forecast. A forecast produced there
  tells the director how likely the proposition is *before* an experiment is
  planned, and gives the later resolution something to score against.

  ## Why a hypothesis may have no forecast

  A hypothesis is only forecastable when it carries an explicit forecast
  specification:

      %{
        proposition: "The thermal model converges within 24 hours",
        outcomes: ["converged", "not_converged"],
        horizon: "24h",
        resolution_criteria: "the model registry records status :operational",
        evidence: [%{"id" => "ev_1", "epistemic_status" => "observed",
                     "source" => "sensor_a"}]
      }

  The hypotheses the Research Director generates today are *causal claims*
  ("the observed behaviour is caused by an identifiable factor"), not
  propositions about a specific future event with an outcome space. Forcing a
  forecast onto them would produce a forecast about an unmeasurable
  proposition. Those hypotheses are therefore marked
  `forecast_status: :not_forecastable` with the reason, rather than being
  given an invented probability.

  ## The three quantities kept apart

  A hypothesis carries three different quantities, and this adapter never
  converts one into another:

    * `confidence` — evidence confidence (how strongly the evidence supports
      the hypothesis). Already present on the hypothesis.
    * `eig_score` — expected information gain, a *heuristic* ranking input.
    * `forecast.probability` — a probabilistic forecast over a declared outcome
      space. Added by this adapter, only when a forecast was actually
      requested and registered.
  """
  alias Tiannara.Forecasting.Bridge

  @schema_version Bridge.schema_version()

  @type spec :: %{
          proposition: String.t(),
          outcomes: [String.t()],
          horizon: String.t(),
          resolution_criteria: String.t(),
          evidence: [map()],
          base_rate: map() | nil,
          model_ref: String.t() | nil
        }

  @doc "The wire schema version this adapter speaks."
  @spec schema_version() :: pos_integer()
  def schema_version, do: @schema_version

  @doc """
  Validates a forecast specification.

  Returns `{:ok, spec}` or `{:error, reason}` with an exact reason. An
  underspecified proposition is refused; it is never given a default.
  """
  @spec validate_spec(term()) :: {:ok, map()} | {:error, atom()}
  def validate_spec(spec) when is_map(spec) do
    with {:ok, proposition} <- require_string(spec, :proposition),
         {:ok, outcomes} <- require_outcomes(spec),
         {:ok, horizon} <- require_string(spec, :horizon),
         {:ok, typed_horizon} <- require_typed_horizon(spec, horizon),
         {:ok, criteria} <- require_string(spec, :resolution_criteria),
         {:ok, evidence} <- require_evidence(spec) do
      {:ok,
       %{
         proposition: proposition,
         outcomes: outcomes,
         horizon: horizon,
         typed_horizon: typed_horizon,
         resolution_criteria: criteria,
         evidence: evidence,
         base_rate: Map.get(spec, :base_rate),
         model_ref: Map.get(spec, :model_ref)
       }}
    end
  end

  # The enforceable temporal contract. A forecast specification that carries
  # only free text is refused: a horizon that cannot be checked is not a
  # horizon.
  defp require_typed_horizon(spec, label) do
    case Tiannara.Forecasting.Contracts.Horizon.from_iso(%{
           start_at: Map.get(spec, :horizon_start),
           end_at: Map.get(spec, :horizon_end),
           policy: Map.get(spec, :horizon_policy, :closed),
           label: label
         }) do
      {:ok, typed_horizon} -> {:ok, typed_horizon}
      {:error, reason} -> {:error, reason}
    end
  end

  def validate_spec(_spec), do: {:error, :missing_forecast_specification}

  @doc """
  Builds the versioned request for a hypothesis.

  The request id is derived from the hypothesis identity and the proposition,
  so a retry of the same hypothesis requests the same forecast rather than
  creating a second one.
  """
  @spec build_request(map(), map()) :: {:ok, map()} | {:error, atom()}
  def build_request(hypothesis, spec) do
    with {:ok, spec} <- validate_spec(spec) do
      {:ok,
       %{
         "v" => @schema_version,
         "request_id" => request_id(hypothesis, spec),
         "question" => spec.proposition,
         "event" => spec.proposition,
         "outcomes" => spec.outcomes,
         "horizon" => spec.horizon,
         "horizon_start" => DateTime.to_iso8601(spec.typed_horizon.start_at),
         "horizon_end" => DateTime.to_iso8601(spec.typed_horizon.end_at),
         "horizon_policy" => Atom.to_string(spec.typed_horizon.policy),
         "evidence" => spec.evidence,
         "signal_ids" => [],
         "base_rate" => spec.base_rate,
         "model_ref" => spec.model_ref,
         "assumptions" => [spec.resolution_criteria],
         "context" => %{
           "priority_id" => input_id(hypothesis),
           "domain" => Map.get(hypothesis, :domain)
         },
         "regime" => nil,
         "provenance" => %{
           "origin" => "research_director",
           "investigation_id" => input_id(hypothesis),
           "requested_by" => "research_director"
         }
       }}
    end
  end

  @doc """
  Requests a probabilistic forecast for a hypothesis through canonical EFDI.

  Returns `{:ok, forecast}` describing the registered forecast, or
  `{:error, reason}`. It never returns a probability it did not obtain from
  EFDI.
  """
  @spec request_forecast(map(), term()) :: {:ok, map()} | {:error, atom()}
  def request_forecast(hypothesis, spec) do
    with {:ok, request} <- build_request(hypothesis, spec),
         {:ok, response} <- call_bridge(request) do
      case response do
        %{"status" => "ok", "forecast" => forecast} when is_map(forecast) ->
          {:ok,
           %{
             forecast_id: forecast["id"],
             question: forecast["question"],
             horizon: forecast["horizon"],
             outcomes: forecast["outcomes"],
             probabilities: forecast["probabilities"],
             uncertainty: forecast["uncertainty"],
             model_ref: forecast["model_ref"],
             evidence_refs: forecast["evidence_refs"] || [],
             request_id: request["request_id"],
             source: :efdi
           }}

        %{"status" => "error", "error" => %{"reason" => reason}} ->
          {:error, reason_atom(reason)}

        _other ->
          {:error, :invalid_forecast_response}
      end
    end
  end

  @doc """
  Attaches the outcome of a forecast request to a hypothesis.

  A hypothesis that could not be forecast records *why*, and its status is
  explicit. Nothing is invented to fill the gap.
  """
  @spec attach(map(), {:ok, map()} | {:error, atom()}) :: map()
  def attach(hypothesis, {:ok, forecast}) do
    hypothesis
    |> Map.put(:forecast, forecast)
    |> Map.put(:forecast_status, :registered)
    |> Map.put(:forecast_id, forecast.forecast_id)
  end

  def attach(hypothesis, {:error, reason}) do
    hypothesis
    |> Map.put(:forecast, nil)
    |> Map.put(:forecast_status, :unavailable)
    |> Map.put(:forecast_error, reason)
  end

  @doc """
  Marks a hypothesis that carries no forecast specification.

  This is not a failure of the forecasting subsystem: the hypothesis is not a
  forecastable proposition. The reason is recorded so that a reader can tell
  the two apart.
  """
  @spec mark_not_forecastable(map(), atom()) :: map()
  def mark_not_forecastable(hypothesis, reason) do
    hypothesis
    |> Map.put(:forecast, nil)
    |> Map.put(:forecast_status, :not_forecastable)
    |> Map.put(:forecast_error, reason)
  end

  # The canonical forecasting authority is reachable only while its
  # application stack is running. If it is not, the request fails closed with
  # an explicit reason: a research pipeline must not crash because the
  # forecasting subsystem is down.
  defp call_bridge(request) do
    {:ok, Bridge.handle_request(request)}
  catch
    :exit, _reason -> {:error, :forecast_engine_unavailable}
  end

  # ------------------------------------------------------------------ helpers

  # The forecast request is identified by the *research input*, not by the
  # hypothesis instance. A hypothesis record is regenerated on every ingest, so
  # keying on it would create a new forecast for the same research input every
  # time the priority was re-ingested.
  defp input_id(hypothesis) do
    Map.get(hypothesis, :source_priority_id) || Map.get(hypothesis, :id)
  end

  defp request_id(hypothesis, spec) do
    base = "#{input_id(hypothesis)}|#{spec.proposition}"
    hash = :crypto.hash(:sha256, base) |> Base.encode16(case: :lower) |> String.slice(0, 16)
    "req_" <> hash
  end

  defp require_string(map, key) do
    case Map.get(map, key) do
      value when is_binary(value) and value != "" -> {:ok, value}
      _ -> {:error, :"missing_#{key}"}
    end
  end

  defp require_outcomes(map) do
    case Map.get(map, :outcomes) do
      outcomes when is_list(outcomes) and length(outcomes) >= 2 ->
        if Enum.all?(outcomes, &(is_binary(&1) and &1 != "")) do
          {:ok, outcomes}
        else
          {:error, :invalid_outcomes}
        end

      _ ->
        {:error, :missing_outcomes}
    end
  end

  defp require_evidence(map) do
    case Map.get(map, :evidence) do
      entries when is_list(entries) and entries != [] ->
        Enum.reduce_while(entries, {:ok, []}, fn entry, {:ok, acc} ->
          with true <- is_map(entry),
               true <- is_binary(Map.get(entry, "id")),
               status when is_binary(status) <- Map.get(entry, "epistemic_status"),
               true <- status in Bridge.epistemic_statuses() do
            {:cont, {:ok, acc ++ [entry]}}
          else
            _ -> {:halt, {:error, :invalid_evidence}}
          end
        end)

      _ ->
        {:error, :missing_evidence}
    end
  end

  defp reason_atom(reason) when is_binary(reason) do
    String.to_existing_atom(reason)
  rescue
    ArgumentError -> :forecast_refused
  end

  defp reason_atom(reason) when is_atom(reason), do: reason
  defp reason_atom(_reason), do: :forecast_refused
end
