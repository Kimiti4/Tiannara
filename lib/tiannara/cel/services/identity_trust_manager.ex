defmodule Tiannara.CEL.Services.IdentityTrustManager do
  use Tiannara.ExecutiveService.Base
  use GenServer
  require Logger

  @trust_decay 0.001
  @decay_interval :timer.hours(1)

  def start_link(_opts), do: GenServer.start_link(__MODULE__, %{}, name: __MODULE__)

  def register_service(service_id, metadata \\ %{}) do
    GenServer.call(__MODULE__, {:register, service_id, metadata})
  end

  def verify_credential(service_id, credential) do
    GenServer.call(__MODULE__, {:verify, service_id, credential})
  end

  def trust_score(service_id) do
    GenServer.call(__MODULE__, {:trust_score, service_id})
  end

  def authorize_action(service_id, capability) do
    GenServer.call(__MODULE__, {:authorize, service_id, capability})
  end

  def report_violation(service_id, severity) do
    GenServer.cast(__MODULE__, {:violation, service_id, severity})
  end

  def report_success(service_id) do
    GenServer.cast(__MODULE__, {:success, service_id})
  end

  def all_identities, do: GenServer.call(__MODULE__, :all)

  @impl true
  def id, do: :identity_trust_manager

  @impl true
  def version, do: "1.0.0"

  @impl true
  def capabilities, do: [:identity_management, :trust_scoring, :credential_verification, :capability_authorization,
    :service_identity, :authentication, :authorization]

  @impl true
  def health, do: :healthy

  @impl true
  def constitutional_score do
    %Tiannara.CEL.Kernel.ConstitutionalScore{
      service_id: :identity_trust_manager,
      health: 1.0,
      constitutional_alignment: 1.0,
      transparency: 0.9,
      explainability: 0.85,
      evidence_quality: 0.9,
      human_oversight: 0.7,
      computed_at: DateTime.utc_now()
    }
  end

  @impl true
  def init(_opts) do
    schedule_decay()
    initial = %{
      kernel: %{id: :kernel, credential: hash("kernel_secret"), trust: 1.0, capabilities: [:admin, :orchestrate], violations: 0, successes: 0, metadata: %{}},
      service_registry: %{id: :service_registry, credential: hash("registry_secret"), trust: 0.95, capabilities: [:register, :discover], violations: 0, successes: 0, metadata: %{}},
      executive_memory: %{id: :executive_memory, credential: hash("memory_secret"), trust: 0.95, capabilities: [:persist, :retrieve], violations: 0, successes: 0, metadata: %{}},
      executive_service_bus: %{id: :executive_service_bus, credential: hash("bus_secret"), trust: 0.95, capabilities: [:publish, :subscribe], violations: 0, successes: 0, metadata: %{}}
    }
    Logger.info("IdentityTrustManager: Initialized with #{map_size(initial)} identities")
    {:ok, %{identities: initial}}
  end

  @impl true
  def handle_call({:register, service_id, metadata}, _from, state) do
    if Map.has_key?(state.identities, service_id) do
      {:reply, {:error, :already_registered}, state}
    else
      credential = hash("cred_#{service_id}_#{:crypto.strong_rand_bytes(16) |> Base.encode16(case: :lower)}")
      identity = %{
        id: service_id,
        credential: credential,
        trust: 0.8,
        capabilities: Map.get(metadata, :capabilities, []),
        violations: 0,
        successes: 0,
        metadata: metadata
      }
      Logger.info("IdentityTrustManager: Registered #{service_id}")
      {:reply, {:ok, credential}, put_in(state, [:identities, service_id], identity)}
    end
  end

  @impl true
  def handle_call({:verify, service_id, credential}, _from, state) do
    case Map.fetch(state.identities, service_id) do
      {:ok, %{credential: stored}} ->
        valid = stored == credential
        {:reply, valid, state}
      :error ->
        {:reply, false, state}
    end
  end

  @impl true
  def handle_call({:trust_score, service_id}, _from, state) do
    case Map.fetch(state.identities, service_id) do
      {:ok, identity} -> {:reply, identity.trust, state}
      :error -> {:reply, {:error, :unknown_identity}, state}
    end
  end

  @impl true
  def handle_call({:authorize, service_id, capability}, _from, state) do
    case Map.fetch(state.identities, service_id) do
      {:ok, %{capabilities: caps, trust: trust}} ->
        authorized = capability in caps and trust >= 0.3
        {:reply, %{authorized: authorized, trust: trust, required: capability}, state}
      :error ->
        {:reply, %{authorized: false, trust: 0.0, required: capability, error: :unknown_identity}, state}
    end
  end

  @impl true
  def handle_call(:all, _from, state) do
    {:reply, Map.values(state.identities), state}
  end

  @impl true
  def handle_cast({:violation, service_id, severity}, state) do
    case Map.fetch(state.identities, service_id) do
      {:ok, identity} ->
        penalty = severity * 0.1
        updated = %{identity |
          trust: max(0.0, identity.trust - penalty),
          violations: identity.violations + 1
        }
        Logger.warning("IdentityTrustManager: #{service_id} violated (severity: #{severity}). Trust: #{Float.round(updated.trust, 4)}")
        {:noreply, put_in(state, [:identities, service_id], updated)}
      :error ->
        {:noreply, state}
    end
  end

  @impl true
  def handle_cast({:success, service_id}, state) do
    case Map.fetch(state.identities, service_id) do
      {:ok, identity} ->
        updated = %{identity |
          trust: min(1.0, identity.trust + 0.02),
          successes: identity.successes + 1
        }
        {:noreply, put_in(state, [:identities, service_id], updated)}
      :error ->
        {:noreply, state}
    end
  end

  @impl true
  def handle_info(:apply_trust_decay, state) do
    new_identities =
      Map.new(state.identities, fn {id, identity} ->
        decayed = %{identity | trust: max(0.0, identity.trust - @trust_decay)}
        {id, decayed}
      end)
    schedule_decay()
    {:noreply, %{state | identities: new_identities}}
  end

  defp schedule_decay do
    Process.send_after(self(), :apply_trust_decay, @decay_interval)
  end

  defp hash(value) when is_binary(value) do
    :crypto.hash(:sha256, value) |> Base.encode16(case: :lower)
  end
end
