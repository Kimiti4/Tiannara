defmodule Tiannara.ASC.CivilizationManager do
  @moduledoc """
  Forms and maintains specialized research civilizations.
  Each civilization develops its own researchers, theories, experiments, and traditions.
  """
  use GenServer
  alias Tiannara.ASC.Models.Civilization

  @default_domains [
    :computation, :physics, :engineering, :robotics,
    :cybersecurity, :medicine, :materials, :energy, :governance
  ]

  def start_link(opts \\ []), do: GenServer.start_link(__MODULE__, %{}, opts)

  def form_civilization(pid, domain), do: GenServer.call(pid, {:form, domain})
  def get_civilization(pid, domain), do: GenServer.call(pid, {:get, domain})
  def list_civilizations(pid), do: GenServer.call(pid, :list)

  @impl true
  def init(_) do
    initial = Enum.reduce(@default_domains, %{}, fn domain, acc ->
      civ = %Civilization{
        id: UUID.uuid4(),
        name: "#{domain |> Atom.to_string() |> String.capitalize()} Civilization",
        domain: domain,
        founded_at: DateTime.utc_now(),
        status: :active
      }
      Map.put(acc, domain, civ)
    end)
    {:ok, %{civilizations: initial}}
  end

  @impl true
  def handle_call({:form, domain}, _from, state) do
    case Map.get(state.civilizations, domain) do
      nil ->
        civ = %Civilization{
          id: UUID.uuid4(), name: "#{domain} Civilization",
          domain: domain, founded_at: DateTime.utc_now(), status: :active
        }
        {:reply, {:ok, civ}, put_in(state, [:civilizations, domain], civ)}
      existing -> {:reply, {:exists, existing}, state}
    end
  end

  @impl true
  def handle_call({:get, domain}, _from, state), do: {:reply, Map.get(state.civilizations, domain), state}

  @impl true
  def handle_call(:list, _from, state), do: {:reply, Map.values(state.civilizations), state}
end
