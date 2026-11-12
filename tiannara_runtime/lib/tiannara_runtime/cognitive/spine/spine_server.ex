defmodule TiannaraRuntime.Cognitive.Spine.SpineServer do
  @moduledoc """
  Host process for the Cognitive Execution Spine.

  The Spine itself is a pure function over existing engines; this process
  exists for three reasons and no others:

    1. to give the Spine a **single, governed entry point** rather than a
       scattering of direct calls;
    2. to own the **adapter configuration** (authority and knowledge), so
       that which authority is in force is a property of the running system
       rather than of each call site;
    3. to give the Spine a **lifecycle** — start, stop, restart — that the
       supervision tree can reason about.

  The adapters are injected through the application environment so that a
  deployment can bind the Spine to a real authority without changing code:

      config :tiannara_runtime, TiannaraRuntime.Cognitive.Spine.SpineServer,
        authority: MyApp.AuthorityAdapter,
        knowledge: MyApp.KnowledgeAdapter

  When an adapter is absent the Spine uses the refusing default, so a started
  but unwired Spine is explicitly unable to authorise or to retain — it is
  never accidentally permissive.
  """
  use GenServer

  alias TiannaraRuntime.Cognitive.Spine.Authority
  alias TiannaraRuntime.Cognitive.Spine.CognitiveExecutionSpine
  alias TiannaraRuntime.Cognitive.Spine.Knowledge

  @name __MODULE__

  def start_link(opts \\ []) do
    {name, opts} = Keyword.pop(opts, :name, @name)
    GenServer.start_link(__MODULE__, opts, name: name)
  end

  @impl true
  def init(opts) do
    config = Application.get_env(:tiannara_runtime, __MODULE__, [])
    config = if is_list(config), do: config, else: []

    authority =
      Keyword.get(opts, :authority) || Keyword.get(config, :authority) || Authority.Refusing

    knowledge =
      Keyword.get(opts, :knowledge) || Keyword.get(config, :knowledge) || Knowledge.Refusing

    {:ok, %{authority: authority, knowledge: knowledge}}
  end

  @doc """
  Runs an investigation through the cognitive cycle.

  Returns `{:ok, result}` with the stage trace, or `{:error, reason, trace}`
  when a chained stage failed.
  """
  @spec run_investigation(map(), keyword()) :: {:ok, map()} | {:error, term(), [map()]}
  def run_investigation(request, opts \\ []) do
    case GenServer.call(@name, {:run, request, opts}, :infinity) do
      {:ok, result} -> {:ok, result}
      {:error, reason, trace} -> {:error, reason, trace}
    end
  end

  @doc "Returns the adapters currently in force."
  @spec adapters() :: %{authority: module(), knowledge: module()}
  def adapters do
    GenServer.call(@name, :adapters)
  end

  @doc "Runs an investigation through a specific Spine instance."
  @spec run_investigation_at(GenServer.server(), map(), keyword()) ::
          {:ok, map()} | {:error, term(), [map()]}
  def run_investigation_at(server, request, opts \\ []) do
    case GenServer.call(server, {:run, request, opts}, :infinity) do
      {:ok, result} -> {:ok, result}
      {:error, reason, trace} -> {:error, reason, trace}
    end
  end

  @doc "Returns the adapters in force for a specific Spine instance."
  @spec adapters_at(GenServer.server()) :: %{authority: module(), knowledge: module()}
  def adapters_at(server) do
    GenServer.call(server, :adapters)
  end

  @impl true
  def handle_call({:run, request, opts}, _from, state) do
    opts =
      opts
      |> Keyword.put_new(:authority, state.authority)
      |> Keyword.put_new(:knowledge, state.knowledge)

    {:reply, CognitiveExecutionSpine.run(request, opts), state}
  end

  def handle_call(:adapters, _from, state) do
    {:reply, %{authority: state.authority, knowledge: state.knowledge}, state}
  end
end
