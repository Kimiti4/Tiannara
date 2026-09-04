defmodule Tiannara.Forecasting.Outcome do
  @moduledoc """
  D2 outcome linking: Forecast → ObservedOutcome, with hindsight isolation.

  An outcome links a forecast to reality. D2 does NOT decide whether an outcome
  is valid; it consumes the existing canonical event infrastructure.

  Rules:
    - forecast-time information and post-outcome information are kept separate.
    - An outcome recorded at/after `forecast.created_at` is linked only when it
      documents the forecast-time snapshot, never retroactively edited.
    - `hindsight_clean?/2` guards against revising the forecast after the fact.
  """

  alias Tiannara.Forecasting.Contracts.Forecast

  @type outcome :: %{
          id: String.t(),
          forecast_id: String.t(),
          observed_outcome: term(),
          observed_at: DateTime.t() | nil,
          source: String.t()
        }

  @spec new(forecast_id :: String.t(), observed_outcome :: term(), map() | Keyword.t()) ::
          outcome()
  def new(forecast_id, observed_outcome, attrs \\ []) when is_binary(forecast_id) do
    m = Map.new(attrs)
    %{
      id: Map.get(m, :id) || Tiannara.Executive.Types.new_id(),
      forecast_id: forecast_id,
      observed_outcome: observed_outcome,
      observed_at: Map.get(m, :observed_at),
      source: Map.get(m, :source, "event_store")
    }
  end

  @doc """
  True when the outcome observation time is at/after the forecast creation time
  (i.e., the outcome could not precede the forecast). This is the hindsight
  isolation pre-condition.
  """
  @spec hindsight_clean?(outcome(), Forecast.t()) :: boolean()
  def hindsight_clean?(_outcome, %Forecast{created_at: nil}), do: true

  def hindsight_clean?(%{observed_at: nil}, _forecast), do: true

  def hindsight_clean?(%{observed_at: at}, %Forecast{created_at: fc}) do
    DateTime.compare(at, fc) in [:gt, :eq]
  end

  @doc """
  Rejects outcomes whose observed_at precedes forecast creation (hindsight
  contamination). Returns `{:ok, outcome}` or `{:error, :hindsight_contamination}`.
  """
  @spec guard!(outcome(), Forecast.t()) :: {:ok, outcome()} | {:error, :hindsight_contamination}
  def guard!(outcome, %Forecast{} = forecast) do
    if hindsight_clean?(outcome, forecast) do
      {:ok, outcome}
    else
      {:error, :hindsight_contamination}
    end
  end
end