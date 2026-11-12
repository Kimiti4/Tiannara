defmodule TiannaraRuntime.Cognitive.Spine.Forecasting do
  @moduledoc """
  The runtime-side port to the application stack's canonical forecasting
  authority (EFDI).

  EFDI lives in the application stack. The Spine lives in the runtime stack.
  The Spine therefore *requests* a probabilistic forecast through this port
  and receives a verified result; it never performs forecasting mathematics
  itself.

  ## The distinction this port protects

  The Spine already has an evidence-confidence capability
  (`Cognitive.Metacognition.ConfidenceEstimator`) and an uncertainty
  decomposition (`UncertaintyAnalyzer`). Those answer *how strongly does the
  available evidence support this?* A probabilistic forecast answers *how
  likely is this specified outcome over this horizon?* They are different
  quantities and one is never converted into the other.

  When no EFDI boundary is wired, this port reports
  `{:error, :forecast_engine_unavailable}`. It never returns a fabricated
  probability, and it never substitutes a confidence score for one.

  ## Wire contract

  The request/response shape is owned by `Tiannara.Forecasting.Bridge` in the
  application stack (schema version 1). This module reproduces it exactly so
  the two sides agree without a compile-time dependency; the conformance test
  pins both sides against the same field list.
  """

  @schema_version 1

  @type request :: map()
  @type response :: map()

  @callback forecast(request()) :: {:ok, response()} | {:error, term()}

  @doc "The wire schema version this port speaks."
  @spec schema_version() :: pos_integer()
  def schema_version, do: @schema_version

  @doc "The request fields, mirroring `Tiannara.Forecasting.Bridge.request_fields/0`."
  @spec request_fields() :: [String.t()]
  def request_fields,
    do: ~w(v request_id question event outcomes horizon evidence signal_ids
           base_rate model_ref assumptions context regime provenance)

  @doc "The response fields, mirroring `Tiannara.Forecasting.Bridge.response_fields/0`."
  @spec response_fields() :: [String.t()]
  def response_fields, do: ~w(v request_id status forecast error)

  # The default adapter reports the canonical forecasting authority as
  # unavailable. It exists so that a Spine which has not been wired to EFDI is
  # explicitly unable to forecast, rather than silently producing something
  # else.
  defmodule Refusing do
    @moduledoc """
    Default forecasting adapter. Refuses every request with
    `{:error, :forecast_engine_unavailable}`.
    """
    @behaviour TiannaraRuntime.Cognitive.Spine.Forecasting

    @impl true
    def forecast(_request), do: {:error, :forecast_engine_unavailable}
  end
end
