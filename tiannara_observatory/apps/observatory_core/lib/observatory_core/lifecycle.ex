defmodule ObservatoryCore.Lifecycle do
  use GenServer

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def start(env) do
    GenServer.call(__MODULE__, {:start, env})
  end

  def stop do
    GenServer.call(__MODULE__, :stop)
  end

  def status do
    GenServer.call(__MODULE__, :status)
  end

  @impl true
  def init(opts) do
    {:ok, %{status: :initialized, started_at: nil, env: opts[:env] || :dev}}
  end

  @impl true
  def handle_call({:start, env}, _from, state) do
    {:reply, :ok, %{state | status: :running, started_at: DateTime.utc_now(), env: env}}
  end

  @impl true
  def handle_call(:stop, _from, state) do
    {:reply, :ok, %{state | status: :stopped}}
  end

  @impl true
  def handle_call(:status, _from, state) do
    {:reply, state, state}
  end
end
