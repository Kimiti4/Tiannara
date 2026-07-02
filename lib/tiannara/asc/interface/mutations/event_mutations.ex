defmodule Tiannara.ASC.Interface.Mutations.EventMutations do
  @moduledoc """
  Event Mutation Operators — evolve event stream definitions through semantic transformations.

  Implements 5 mutation types:
  - Add event
  - Remove event
  - Split event (by consumer or field)
  - Merge events
  - Change delivery guarantee

  Each mutation returns a Mutation record with full provenance for law discovery.
  """

  alias Tiannara.ASC.Interface.{Event, Mutation}
  alias Tiannara.ASC.Interface.Fitness

  @doc """
  Add a new event to the genome.

  Creates an event from workflow step and adds it to the genome.

  ## Returns

  - {new_genome, mutation_record}

  """
  def add_event(genome, workflow, step_index) do
    new_event = Event.from_workflow(workflow, step_index)
    new_events = genome.events ++ [new_event]

    fitness_before = Fitness.calculate(genome)
    new_genome = %{genome | events: new_events}
    fitness_after = Fitness.calculate(new_genome)

    mutation = Mutation.new(
      :add_event,
      new_event.id,
      :event,
      nil,
      new_event,
      "Added event for workflow step #{step_index}",
      fitness_before,
      fitness_after,
      genome.generation
    )

    {new_genome, mutation}
  end

  @doc """
  Remove an event from the genome.

  Removes the specified event by ID.

  ## Returns

  - {new_genome, mutation_record} or {:error, :not_found}

  """
  def remove_event(genome, event_id) do
    case Enum.find_index(genome.events, fn e -> e.id == event_id end) do
      nil ->
        {:error, :not_found}

      index ->
        removed_event = Enum.at(genome.events, index)
        new_events = List.delete_at(genome.events, index)

        fitness_before = Fitness.calculate(genome)
        new_genome = %{genome | events: new_events}
        fitness_after = Fitness.calculate(new_genome)

        mutation = Mutation.new(
          :remove_event,
          event_id,
          :event,
          removed_event,
          nil,
          "Removed event #{event_id}",
          fitness_before,
          fitness_after,
          genome.generation
        )

        {new_genome, mutation}
    end
  end

  @doc """
  Split an event into multiple specialized events.

  Uses the Event.split/2 strategy to divide the event.

  ## Parameters

  - `event_id` — ID of event to split
  - `split_strategy` — :by_consumer or :by_field

  ## Returns

  - {new_genome, mutation_record} or {:error, :not_found}

  """
  def split_event(genome, event_id, split_strategy \\ :by_consumer) do
    case Enum.find(genome.events, fn e -> e.id == event_id end) do
      nil ->
        {:error, :not_found}

      event ->
        split_events = Event.split(event, split_strategy)

        # Remove original event and add split events
        remaining = Enum.reject(genome.events, fn e -> e.id == event_id end)
        new_events = remaining ++ split_events

        fitness_before = Fitness.calculate(genome)
        new_genome = %{genome | events: new_events}
        fitness_after = Fitness.calculate(new_genome)

        mutation = Mutation.new(
          :split_event,
          event_id,
          :event,
          event,
          split_events,
          "Split event by #{split_strategy}",
          fitness_before,
          fitness_after,
          genome.generation
        )

        {new_genome, mutation}
    end
  end

  @doc """
  Merge two events into a consolidated event.

  Combines consumers and schemas from both events.

  ## Returns

  - {new_genome, mutation_record}

  """
  def merge_events(genome, event_id1, event_id2) do
    event1 = Enum.find(genome.events, fn e -> e.id == event_id1 end)
    event2 = Enum.find(genome.events, fn e -> e.id == event_id2 end)

    if event1 && event2 do
      merged = Event.merge(event1, event2)

      # Remove both originals and add merged
      remaining = Enum.reject(genome.events, fn e ->
        e.id == event_id1 or e.id == event_id2
      end)
      new_events = remaining ++ [merged]

      fitness_before = Fitness.calculate(genome)
      new_genome = %{genome | events: new_events}
      fitness_after = Fitness.calculate(new_genome)

      mutation = Mutation.new(
        :merge_event,
        "#{event_id1}_#{event_id2}",
        :event,
        [event1, event2],
        merged,
        "Merged events into consolidated stream",
        fitness_before,
        fitness_after,
        genome.generation
      )

      {new_genome, mutation}
    else
      {:error, :not_found}
    end
  end

  @doc """
  Change event delivery guarantee.

  Upgrades or downgrades delivery semantics (e.g., at_least_once → exactly_once).

  ## Returns

  - {new_genome, mutation_record} or {:error, :not_found}

  """
  def change_delivery_guarantee(genome, event_id, new_guarantee) do
    case Enum.find_index(genome.events, fn e -> e.id == event_id end) do
      nil ->
        {:error, :not_found}

      index ->
        old_event = Enum.at(genome.events, index)
        new_event = Event.change_delivery_guarantee(old_event, new_guarantee)

        new_events = List.replace_at(genome.events, index, new_event)

        fitness_before = Fitness.calculate(genome)
        new_genome = %{genome | events: new_events}
        fitness_after = Fitness.calculate(new_genome)

        mutation = Mutation.new(
          :change_delivery_guarantee,
          event_id,
          :event,
          old_event,
          new_event,
          "Changed delivery guarantee to #{new_guarantee}",
          fitness_before,
          fitness_after,
          genome.generation
        )

        {new_genome, mutation}
    end
  end

  @doc """
  Add a consumer to an event.

  Expands the event's consumer list.

  ## Returns

  - {new_genome, mutation_record} or {:error, :not_found}

  """
  def add_consumer(genome, event_id, consumer) do
    case Enum.find_index(genome.events, fn e -> e.id == event_id end) do
      nil ->
        {:error, :not_found}

      index ->
        old_event = Enum.at(genome.events, index)
        new_event = Event.add_consumer(old_event, consumer)

        new_events = List.replace_at(genome.events, index, new_event)

        fitness_before = Fitness.calculate(genome)
        new_genome = %{genome | events: new_events}
        fitness_after = Fitness.calculate(new_genome)

        mutation = Mutation.new(
          :add_consumer,
          event_id,
          :event,
          old_event,
          new_event,
          "Added consumer: #{consumer}",
          fitness_before,
          fitness_after,
          genome.generation
        )

        {new_genome, mutation}
    end
  end

  @doc """
  Remove a consumer from an event.

  Contracts the event's consumer list.

  ## Returns

  - {new_genome, mutation_record} or {:error, :not_found}

  """
  def remove_consumer(genome, event_id, consumer) do
    case Enum.find_index(genome.events, fn e -> e.id == event_id end) do
      nil ->
        {:error, :not_found}

      index ->
        old_event = Enum.at(genome.events, index)
        new_event = Event.remove_consumer(old_event, consumer)

        new_events = List.replace_at(genome.events, index, new_event)

        fitness_before = Fitness.calculate(genome)
        new_genome = %{genome | events: new_events}
        fitness_after = Fitness.calculate(new_genome)

        mutation = Mutation.new(
          :remove_consumer,
          event_id,
          :event,
          old_event,
          new_event,
          rationale: "Removed consumer: #{consumer}",
          fitness_before: fitness_before,
          fitness_after: fitness_after,
          generation: genome.generation
        )

        {new_genome, mutation}
    end
  end
end
