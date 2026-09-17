defmodule EventStore.Reader do
  alias EventStore.Schema.Event
  alias EventStore.Repo
  import Ecto.Query

  def get(id) do
    Repo.get(Event, id)
  end

  def list_by_domain(domain, opts \\ []) do
    query = from(e in Event, where: e.domain == ^domain, order_by: [asc: e.timestamp])

    query
    |> maybe_paginate(opts)
    |> Repo.all()
  end

  def list_by_time_range(start_time, end_time, opts \\ []) do
    query =
      from(e in Event,
        where: e.timestamp >= ^start_time and e.timestamp <= ^end_time,
        order_by: [asc: e.timestamp]
      )

    query
    |> maybe_paginate(opts)
    |> Repo.all()
  end

  def count_by_domain(domain) do
    Repo.aggregate(from(e in Event, where: e.domain == ^domain), :count, :id)
  end

  defp maybe_paginate(query, opts) do
    query
    |> then(fn q -> if opts[:limit], do: from(q, limit: ^opts[:limit]), else: q end)
    |> then(fn q -> if opts[:offset], do: from(q, offset: ^opts[:offset]), else: q end)
  end
end
