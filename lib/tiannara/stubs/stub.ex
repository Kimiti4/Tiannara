defmodule Tiannara.Stub do
  @moduledoc """
  Helper for defining constitutional stubs.

  Usage:

      defmodule TiannaraOS.LifecycleRegistry do
        use Tiannara.Stub,
          subsystem: :os,
          phase: "Omega+",
          priority: :high

        def track_entity(module, entity_id, event_type, metadata) do
          stub_result(:track_entity, [module, entity_id, event_type, metadata], {:ok, :tracked})
        end
      end

  Every function defined this way will:
  - Register itself in the StubRegistry
  - Emit telemetry on every call
  - Return an explicit {:stub, ...} or a configured default
  """

  defmacro __using__(opts) do
    quote do
      @stub_opts unquote(opts)
      @stub_subsystem Keyword.get(@stub_opts, :subsystem, :unknown)
      @stub_phase Keyword.get(@stub_opts, :phase, "Omega+")
      @stub_priority Keyword.get(@stub_opts, :priority, :medium)

      require Logger

      defp stub_result(function, args, default \\ nil) do
        if Process.whereis(Tiannara.StubRegistry) do
          Tiannara.StubRegistry.record_call(__MODULE__, function, length(args),
            subsystem: @stub_subsystem,
            phase: @stub_phase,
            priority: @stub_priority
          )
        end

        Logger.debug("[Stub] #{inspect(__MODULE__)}.#{function}/#{length(args)} called")

        case default do
          {:stub, _} = result -> result
          nil -> {:stub, %{module: __MODULE__, function: function, args: args, phase: @stub_phase}}
          value -> value
        end
      end
    end
  end
end
