defmodule TiannaraRuntime.Mathematics.Validation.Campaign do
  @moduledoc """
  Phase 16.X.95 — Constitutional Mathematics Validation Campaign

  Defines the behaviour that every validation campaign must implement.
  Each campaign runs a specific class of mathematical validation and
  returns structured results for aggregation and reporting.
  """

  @callback run(opts :: keyword()) :: {:ok, map()} | {:error, String.t()}

  @callback name() :: String.t()

  @callback description() :: String.t()
end
