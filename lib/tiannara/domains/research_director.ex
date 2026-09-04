defmodule Tiannara.Domains.ResearchDirector do
  use GenServer
  require Logger

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def register_domain(domain_module) do
    GenServer.call(__MODULE__, {:register, domain_module})
  end

  def discover(domain_name, context) do
    GenServer.call(__MODULE__, {:execute, domain_name, :discover, [context]})
  end

  def evaluate(domain_name, hypothesis) do
    GenServer.call(__MODULE__, {:execute, domain_name, :evaluate, [hypothesis]})
  end

  def get_all_metrics do
    GenServer.call(__MODULE__, :get_metrics)
  end

  @impl true
  def init(_opts) do
    Process.put(:domains, %{})
    Logger.info("[ResearchDirector] Initialized.")
    {:ok, %{}}
  end

  @impl true
  def handle_call({:register, domain_module}, _from, state) do
    domains = Process.get(:domains)
    name = domain_module.__info__(:module) |> to_string() |> String.split(".") |> List.last() |> String.downcase() |> String.to_atom()
    new_domains = Map.put(domains, name, domain_module)
    Process.put(:domains, new_domains)
    Logger.info("[ResearchDirector] Registered domain: #{name}")
    {:reply, {:ok, name}, state}
  end

  @impl true
  def handle_call({:execute, domain_name, function, args}, _from, state) do
    domains = Process.get(:domains)
    case Map.get(domains, domain_name) do
      nil -> {:reply, {:error, :domain_not_found}, state}
      module ->
        start = System.monotonic_time(:microsecond)
        result = apply(module, function, args)
        duration = System.monotonic_time(:microsecond) - start
        :telemetry.execute([:tiannara, :domains, :execution], %{duration: duration}, %{domain: domain_name, function: function})
        {:reply, result, state}
    end
  end

  @impl true
  def handle_call(:get_metrics, _from, state) do
    domains = Process.get(:domains)
    metrics = Enum.map(domains, fn {name, module} -> {name, module.metrics()} end) |> Map.new()
    {:reply, {:ok, metrics}, state}
  end
end
