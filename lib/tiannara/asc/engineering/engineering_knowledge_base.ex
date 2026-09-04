defmodule Tiannara.ASC.Engineering.KnowledgeBase do
  use GenServer

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def store_design(design) do
    GenServer.cast(__MODULE__, {:store, design})
  end

  def store_lesson(failure) do
    GenServer.cast(__MODULE__, {:lesson, failure})
  end

  def find_by_domain(domain) do
    GenServer.call(__MODULE__, {:find_domain, domain})
  end

  def patterns, do: GenServer.call(__MODULE__, :patterns)

  def lessons, do: GenServer.call(__MODULE__, :lessons)

  def stats, do: GenServer.call(__MODULE__, :stats)

  @impl true
  def init(_opts) do
    {:ok, %{
      patterns: [],
      lessons: [],
      heuristics: default_heuristics(),
      started_at: DateTime.utc_now()
    }}
  end

  @impl true
  def handle_cast({:store, design}, state) do
    pattern = %{
      id: Map.get(design, :id),
      name: Map.get(design, :name),
      domain: Map.get(design, :domain),
      architecture: Map.get(design, :architecture),
      composite_score: Map.get(design, :composite_score, 0.5),
      stored_at: DateTime.utc_now()
    }

    {:noreply, %{state | patterns: [pattern | state.patterns] |> Enum.take(1000)}}
  end

  @impl true
  def handle_cast({:lesson, failure}, state) do
    lesson = %{
      id: "lesson_#{:crypto.strong_rand_bytes(6) |> Base.encode16(case: :lower)}",
      description: Map.get(failure, :description, "unnamed failure"),
      domain: Map.get(failure, :domain, :general),
      cause: Map.get(failure, :cause, :unknown),
      prevention: Map.get(failure, :prevention, "unknown"),
      stored_at: DateTime.utc_now()
    }

    {:noreply, %{state | lessons: [lesson | state.lessons] |> Enum.take(500)}}
  end

  @impl true
  def handle_call({:find_domain, domain}, _from, state) do
    results = Enum.filter(state.patterns, &(&1.domain == domain))
    {:reply, results, state}
  end

  @impl true
  def handle_call(:patterns, _from, state) do
    {:reply, state.patterns, state}
  end

  @impl true
  def handle_call(:lessons, _from, state) do
    {:reply, state.lessons, state}
  end

  @impl true
  def handle_call(:stats, _from, state) do
    {:reply, %{
      patterns: length(state.patterns),
      lessons: length(state.lessons),
      heuristics: length(state.heuristics)
    }, state}
  end

  @impl true
  def handle_info(_, state), do: {:noreply, state}

  defp default_heuristics do
    [
      %{id: "H-01", rule: "Prefer loose coupling over tight integration", domain: :general},
      %{id: "H-02", rule: "Add redundancy for safety-critical paths", domain: :reliability_engineering},
      %{id: "H-03", rule: "Design for testability from the start", domain: :general},
      %{id: "H-04", rule: "Minimize single points of failure", domain: :reliability_engineering},
      %{id: "H-05", rule: "Prefer standard components over custom where possible", domain: :manufacturing}
    ]
  end
end
