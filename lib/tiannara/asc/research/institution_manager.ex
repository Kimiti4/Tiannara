defmodule Tiannara.ASC.Research.InstitutionManager do
  use GenServer

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def create_institution(name, domain, specialization) do
    GenServer.call(__MODULE__, {:create, name, domain, specialization})
  end

  def institutions, do: GenServer.call(__MODULE__, :institutions)

  def find_by_domain(domain), do: GenServer.call(__MODULE__, {:find_by_domain, domain})

  @impl true
  def init(_opts) do
    defaults = [
      create_default("Physics Institute", :physics, "fundamental physics and materials"),
      create_default("Computing Institute", :computing, "algorithms, AI, and systems"),
      create_default("Biology Institute", :biology, "molecular biology and genetics"),
      create_default("Engineering Institute", :engineering, "applied engineering and design"),
      create_default("Mathematics Institute", :computation, "pure and applied mathematics")
    ]

    institutions = Map.new(defaults, fn inst -> {inst.domain, inst} end)

    {:ok, %{institutions: institutions, started_at: DateTime.utc_now()}}
  end

  @impl true
  def handle_call({:create, name, domain, specialization}, _from, state) do
    institution = %{
      id: "inst_#{:crypto.strong_rand_bytes(6) |> Base.encode16(case: :lower)}",
      name: name,
      domain: domain,
      specialization: specialization,
      knowledge_count: 0,
      active_programs: 0,
      created_at: DateTime.utc_now()
    }

    {:reply, {:ok, institution.id}, put_in(state.institutions[domain], institution)}
  end

  @impl true
  def handle_call(:institutions, _from, state) do
    {:reply, Map.values(state.institutions), state}
  end

  @impl true
  def handle_call({:find_by_domain, domain}, _from, state) do
    case Map.fetch(state.institutions, domain) do
      {:ok, inst} -> {:reply, {:ok, inst}, state}
      :error -> {:reply, {:error, :not_found}, state}
    end
  end

  @impl true
  def handle_info(_, state), do: {:noreply, state}

  defp create_default(name, domain, specialization) do
    %{
      id: "inst_#{domain}",
      name: name,
      domain: domain,
      specialization: specialization,
      knowledge_count: 0,
      active_programs: 0,
      created_at: DateTime.utc_now()
    }
  end
end
