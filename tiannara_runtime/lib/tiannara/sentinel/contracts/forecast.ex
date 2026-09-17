defmodule Tiannara.Sentinel.Contracts.Forecast do
  @moduledoc """
  Represents a trend analysis or forecasted collapse risk.
  """
  defstruct [:id, :target, :risk_level, :confidence, :contributing_factors, :timestamp]

  @type t :: %__MODULE__{
          id: String.t(),
          target: atom() | String.t(),
          risk_level: Tiannara.Sentinel.Contracts.Severity.t(),
          confidence: float(),
          contributing_factors: map(),
          timestamp: integer()
        }
end
