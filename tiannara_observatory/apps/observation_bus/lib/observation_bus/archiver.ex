defmodule ObservationBus.Archiver do
  @moduledoc """
  Event archiver — manages event lifecycle stages.

  Lifecycle:
    * **Hot** — events in active memory (buffers, queues)
    * **Warm** — events in ETS tables (lineage, recent history)
    * **Cold** — events in Event Store database
    * **Archive** — compressed events in long-term storage
    * **Permanent** — constitutionally-critical events (certifications, discoveries)
  """

  alias ObservationBus.Event

  @doc """
  Archives an event, transitioning it through the lifecycle.
  """
  @spec archive(Event.t()) :: :ok
  def archive(%Event{domain: domain, id: id} = event) do
    stage = lifecycle_stage(event)

    :telemetry.execute([:observation_bus, :archive], %{count: 1}, %{
      domain: domain,
      stage: stage,
      event_id: id
    })

    :ok
  end

  @doc """
  Returns the lifecycle stage for an event based on its properties.
  """
  @spec lifecycle_stage(Event.t()) :: :hot | :warm | :cold | :archive | :permanent
  def lifecycle_stage(%Event{priority: prio, domain: domain}) do
    cond do
      prio >= 80 -> :permanent
      domain in ["certification", "constitutional"] -> :permanent
      prio >= 50 -> :warm
      true -> :cold
    end
  end

  @doc """
  Returns archive statistics.
  """
  @spec stats() :: map()
  def stats do
    %{
      total_archived: 0,
      hot: 0,
      warm: 0,
      cold: 0,
      archive: 0,
      permanent: 0,
    }
  end
end
