defmodule Tiannara.ExecutiveService.Base do
  @moduledoc """
  Default implementations for the Tiannara.ExecutiveService behaviour.

  Use in your service module:

      defmodule MyService do
        use Tiannara.ExecutiveService.Base

        def id, do: :my_service
        def version, do: "2.0.0"
        ...
      end

  Provides __using__ macro that injects defaults and a telemetry
  emission helper.
  """

  defmacro __using__(_opts) do
    quote location: :keep do
      @behaviour Tiannara.ExecutiveService

      @impl true
      def capabilities, do: []

      @impl true
      def dependencies, do: []

      @impl true
      def boot(_opts), do: {:ok, self()}

      @impl true
      def shutdown(_reason), do: :ok

      @impl true
      def health, do: :healthy

      @impl true
      def recover(_snapshot), do: :ok

      @impl true
      def upgrade(_version, _opts), do: :ok

      @impl true
      def degrade(_opts), do: :ok

      @impl true
      def metadata, do: %{}

      @impl true
      def handle_event(_event_type, _payload, _metadata), do: :ok

      @impl true
      def validate_state, do: :ok

      defoverridable capabilities: 0, dependencies: 0, boot: 1, shutdown: 1,
                     health: 0, recover: 1, upgrade: 2, degrade: 1,
                     metadata: 0, handle_event: 3, validate_state: 0

      def emit_constitutional_event(event_type, payload, metadata \\ %{}) do
        :telemetry.execute(
          [:tiannara, :executive, :constitutional],
          %{event_type: event_type},
          Map.merge(metadata, %{service: id(), version: version(), payload: payload})
        )
      end
    end
  end
end
