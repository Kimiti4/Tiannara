defmodule Tiannara.Telemetry.Adapter do
  @moduledoc """
  Contract for telemetry sources. Replaceable per source (BEAM runtime, OS,
  hardware, external services) behind one interface.

  Constitutional basis: Replaceability, Modularity, "Avoid designs dependent on
  any single ... platform."
  """

  @callback collect(opts :: keyword()) :: Tiannara.Telemetry.Observation.t()
end

defmodule Tiannara.Telemetry.RuntimeAdapter do
  @moduledoc """
  Live BEAM-runtime telemetry adapter. Collects REAL runtime metrics (memory,
  process count, reductions, run queue) rather than synthetic records — this is
  what converts the Sentinel from dry-run to live observation.

  Constitutional basis: Observability, "Detect degraded performance",
  Bottleneck Discovery ("Memory", "Scheduling").
  """
  @behaviour Tiannara.Telemetry.Adapter

  alias Tiannara.Telemetry.Observation

  @impl true
  def collect(_opts) do
    mem = :erlang.memory()

    %Observation{
      id: System.unique_integer([:monotonic]),
      timestamp: System.system_time(:millisecond),
      source: :beam_runtime,
      metrics: %{
        total_memory: Keyword.get(mem, :total),
        process_memory: Keyword.get(mem, :processes),
        process_count: :erlang.system_info(:process_count),
        reductions: elem(:erlang.statistics(:reductions), 0),
        run_queue: :erlang.statistics(:run_queue)
      }
    }
  end
end