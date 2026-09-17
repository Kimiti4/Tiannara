defmodule ObservatoryCore.Boot.Phase do
  @moduledoc "A single boot phase with up/down callbacks and telemetry."
  require Logger

  defstruct [:name, :up, :down, :deps, :timeout_ms, :status]

  @type t :: %__MODULE__{
          name: atom(),
          up: function(),
          down: function(),
          deps: [atom()],
          timeout_ms: pos_integer(),
          status: :pending | :running | :completed | :failed
        }

  def new(name, opts \\ []) do
    %__MODULE__{
      name: name,
      up: opts[:up] || default_handler(name, :up),
      down: opts[:down] || default_handler(name, :down),
      deps: opts[:deps] || [],
      timeout_ms: opts[:timeout_ms] || 10_000,
      status: :pending
    }
  end

  defp default_handler(name, direction) do
    fn ->
      Logger.info("[Boot] #{direction} phase: #{name}")
      :ok
    end
  end
end
