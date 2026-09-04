defmodule Tiannara.Runtime.ExecutiveMemory.Supervisor do
  @moduledoc """
  Ω.0.1 Executive Memory Hardening — Isolated Supervisor.

  Isolates Executive Memory from the main Application tree with its own
  supervision hierarchy. If, despite all safe-execution wrappers, the
  GenServer somehow crashes, this supervisor restarts it **without bringing
  down the Civilization Kernel**.

  ## Strategy

  - **`:one_for_one`** — only the memory process is restarted; no other
    children are affected.
  - **`:permanent` restart** — ensures GenServer always comes back.
  - **`:brutal_kill` shutdown** — prevents hanging during cascading failures.
  - **10 restarts per 60 seconds** — prevents restart storms while allowing
    legitimate recovery.

  ## Constitutional Alignment

  - **Runtime Never Dies:** The supervisor is the secondary containment
    boundary. If the GenServer itself crashes (beyond `safe_execute/2`),
    the supervisor restarts it in isolation.
  - **No Cascading Failures:** A memory crash will never propagate to other
    subsystems because this supervisor is a separate tree in the supervision
    hierarchy.
  """

  use Supervisor
  require Logger

  @doc """
  Starts the Executive Memory supervisor.

  ## Options
    * `:primary_path` — forwarded to `ExecutiveMemory`
    * `:backup_path` — forwarded to `ExecutiveMemory`
    * `:wal_path` — forwarded to `ExecutiveMemory`
  """
  @spec start_link(keyword()) :: Supervisor.on_start()
  def start_link(opts \\ []) do
    Supervisor.start_link(__MODULE__, opts, [])
  end

  @impl true
  def init(opts) do
    # Allow overriding the GenServer name for testing with multiple instances
    gen_server_name = Keyword.get(opts, :gen_server_name, Tiannara.Runtime.ExecutiveMemory)
    child_opts = Keyword.put(opts, :name, gen_server_name)

    children = [
      # The memory process itself
      # restart: :permanent ensures it always comes back
      # shutdown: :brutal_kill prevents hanging during cascading failures
      %{
        id: gen_server_name,
        start: {Tiannara.Runtime.ExecutiveMemory, :start_link, [child_opts]},
        restart: :permanent,
        shutdown: :brutal_kill,
        type: :worker
      }
    ]

    Logger.info("[ExecutiveMemory:Supervisor] Starting with :one_for_one strategy")

    Supervisor.init(children,
      strategy: :one_for_one,
      max_restarts: 10,
      period: 60
    )
  end

  @doc """
  Returns the current operational status of the isolated supervisor tree.

  Useful for health checks and observability probes.
  """
  @spec health(pid()) :: %{
          active_children: non_neg_integer(),
          supervisors: non_neg_integer(),
          workers: non_neg_integer(),
          specs: non_neg_integer()
        }
  def health(sup_pid) do
    %{
      active_children: Supervisor.count_children(sup_pid).active,
      supervisors: Supervisor.count_children(sup_pid).supervisors,
      workers: Supervisor.count_children(sup_pid).workers,
      specs: Supervisor.count_children(sup_pid).specs
    }
  end
end