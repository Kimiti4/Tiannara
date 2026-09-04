defmodule Tiannara.SOPL.Supervisor do
  @moduledoc "Self-Organizing Principle Layer — law evolution, archetype discovery, meta-genome management"
  use Supervisor
  require Logger

  def start_link(opts \\ []) do
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    children = [
      Tiannara.SOPL.LawAttractorRegistry,
      Tiannara.SOPL.LawArchaeology,
      Tiannara.SOPL.LawUnknownRegistry
    ]
    Supervisor.init(children, strategy: :one_for_one)
  end

  def health, do: all_alive?([Tiannara.SOPL.LawAttractorRegistry, Tiannara.SOPL.LawArchaeology, Tiannara.SOPL.LawUnknownRegistry])
  defp all_alive?(mods) do
    Enum.all?(mods, fn mod -> pid = Process.whereis(mod); pid != nil && Process.alive?(pid) end)
  end
end
