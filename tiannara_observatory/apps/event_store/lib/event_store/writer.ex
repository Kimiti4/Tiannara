defmodule EventStore.Writer do
  alias EventStore.Schema.Event
  alias EventStore.Repo

  def write(event_attrs) do
    %Event{}
    |> Event.changeset(event_attrs)
    |> Repo.insert()
  end

  def write_batch(events) do
    Repo.insert_all(Event, events)
  end
end
