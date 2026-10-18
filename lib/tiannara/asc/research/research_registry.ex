defmodule Tiannara.ASC.Research.ResearchRegistry do
  @moduledoc """
  Registry of ASC research programs (Phase 6/11).

  Real GenServer-backed paths (scan A4/A4b):
  * program register/read and fitness-based allocation — registration assigns
    the registry key as the program's `:id` when the struct has an id slot,
    so immune threats (`source_id: prog.id`) resolve to the same key;
  * telemetry metric persistence — `update_program_metrics/2` merges every
    overlapping numeric delta field into the stored program and accumulates
    the full delta (readable via `get_program_metrics/1`);
  * immune freeze — `freeze_program/1` marks a program frozen (budget 0,
    fitness 0.0) and `allocate_resources/1` excludes frozen programs;
  * surviving-genome storage — `store_surviving_genomes/1` and
    `get_surviving_genomes/0` round-trip through registry state.

  `apply_engineering_roi/2` remains a declared fail-closed stub: no real
  ROI-feedback semantics exist yet — tracked as A4b in the
  production-readiness scan.
  """
  use GenServer
  require Logger

  alias Tiannara.ASC.Research.ResearchProgram

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def init(_) do
    {:ok, %{programs: %{}, genomes: [], metrics: %{}}}
  end

  def register_program(program) do
    GenServer.call(__MODULE__, {:register, program})
  end

  def handle_call({:register, program}, _from, state) do
    prog_id = "program_#{program.domain}"
    program = assign_id_if_empty(program, prog_id)
    Logger.info("📚 [ResearchRegistry] Registered new research program for domain: #{program.domain}")
    {:reply, prog_id, put_program(state, prog_id, program)}
  end

  # Real read path (scan A4): returns every program registered in GenServer
  # state (ResearchProgram/ResearchGenome structs). Was two hardcoded mock
  # maps that made the Epistemic Closure scan decide on fiction. The registry
  # is supervised under Tiannara.ASC.Supervisor; if it is not running,
  # GenServer.call exits — callers fail closed instead of scanning fixtures.
  def get_all_programs do
    get_programs() |> Map.values()
  end

  # Real freeze path (scan A4b): was a log line that returned :ok without
  # touching state. Unknown ids fail closed instead of pretending.
  def freeze_program(prog_id) do
    GenServer.call(__MODULE__, {:freeze, prog_id})
  end

  def handle_call({:freeze, prog_id}, _from, state) do
    case get_program(state, prog_id) do
      nil ->
        {:reply, {:error, :not_found}, state}

      %ResearchProgram{} = program ->
        frozen = %{program | frozen: true, budget: 0, program_fitness: 0.0}
        Logger.warning("🧊 [ResearchRegistry] Program #{prog_id} frozen by Immune System. Budget set to 0.")
        {:reply, {:ok, frozen}, put_program(state, prog_id, frozen)}

      other ->
        frozen = Map.put(other, :frozen, true)
        Logger.warning("🧊 [ResearchRegistry] Entity #{prog_id} frozen by Immune System.")
        {:reply, {:ok, frozen}, put_program(state, prog_id, frozen)}
    end
  end

  # Real metric persistence (scan A4b): was `do: :ok` while discarding every
  # telemetry delta. Overlapping numeric fields merge into the stored
  # program; the full delta accumulates under get_program_metrics/1.
  def update_program_metrics(program_id, metrics) do
    GenServer.call(__MODULE__, {:update_metrics, program_id, metrics})
  end

  def handle_call({:update_metrics, program_id, delta}, _from, state) when is_map(delta) do
    case get_program(state, program_id) do
      nil ->
        {:reply, {:error, :not_found}, state}

      program ->
        updated =
          Enum.reduce(Map.keys(delta), program, fn key, acc ->
            case {Map.get(acc, key), Map.get(delta, key)} do
              {old, inc} when is_number(old) and is_number(inc) -> Map.put(acc, key, old + inc)
              _ -> acc
            end
          end)

        merged_delta =
          Map.merge(Map.get(state.metrics, program_id, %{}), delta, fn _k, old, inc ->
            if is_number(old) and is_number(inc), do: old + inc, else: inc
          end)

        new_state = %{
          state
          | programs: Map.put(state.programs, program_id, updated),
            metrics: Map.put(state.metrics, program_id, merged_delta)
        }

        {:reply, {:ok, updated}, new_state}
    end
  end

  def handle_call({:update_metrics, _program_id, _delta}, _from, state) do
    {:reply, {:error, :invalid_delta}, state}
  end

  def get_program_metrics(program_id) do
    GenServer.call(__MODULE__, {:get_program_metrics, program_id})
  end

  def handle_call({:get_program_metrics, program_id}, _from, state) do
    case Map.fetch(state.metrics, program_id) do
      {:ok, metrics} -> {:reply, {:ok, metrics}, state}
      :error -> {:reply, {:error, :not_found}, state}
    end
  end

  # Frozen programs receive no allocation — this is what makes the immune
  # system's "Budget set to 0" claim true (scan A4b). Entities without an
  # id slot sort/default defensively (registry state may hold genome structs).
  def allocate_resources(budget) do
    programs = Enum.reject(get_programs_by_fitness(), &Map.get(&1, :frozen, false))
    case programs do
      [] -> %{}
      list ->
        count = length(list)
        per_prog = div(budget, count)
        Map.new(list, fn p -> {Map.get(p, :id), per_prog} end)
    end
  end

  def get_programs do
    GenServer.call(__MODULE__, :get_programs)
  end

  def get_programs_by_fitness do
    case GenServer.call(__MODULE__, :get_programs) do
      prog_map when prog_map == %{} -> []
      prog_map ->
        prog_map
        |> Map.values()
        |> Enum.sort_by(&Map.get(&1, :program_fitness, 0.0), :desc)
    end
  end

  def handle_call(:get_programs, _from, state), do: {:reply, state.programs, state}

  # Real genome storage (scan A4b): was a constant `[]` while
  # store_surviving_genomes/1 discarded what Phase 7 survived.
  def get_surviving_genomes do
    GenServer.call(__MODULE__, :get_genomes)
  end

  def handle_call(:get_genomes, _from, state), do: {:reply, state.genomes, state}

  def store_surviving_genomes(genomes) when is_list(genomes) do
    GenServer.call(__MODULE__, {:store_genomes, genomes})
  end

  def store_surviving_genomes(_invalid), do: {:error, :invalid_genomes}

  def handle_call({:store_genomes, genomes}, _from, state) do
    {:reply, {:ok, length(genomes)}, %{state | genomes: genomes}}
  end

  # Declared fail-closed stub (scan A4b): no real ROI-feedback semantics
  # exist — the registry has no genome fitness to update and the callers'
  # "ROI fed back" logs were theatrical. Callers now branch on this result.
  def apply_engineering_roi(_program_id, _roi), do: {:error, :not_implemented}

  defp get_program(state, prog_id), do: Map.get(state.programs, prog_id)

  defp put_program(state, prog_id, program),
    do: %{state | programs: Map.put(state.programs, prog_id, program)}

  defp assign_id_if_empty(%{id: nil} = program, prog_id), do: %{program | id: prog_id}
  defp assign_id_if_empty(%{id: _} = program, _prog_id), do: program
  defp assign_id_if_empty(program, _prog_id), do: program
end
