defmodule Tiannara.ASC.Reality.InfrastructurePlanner do
  use GenServer

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def plan(deployment_id, target, params \\ %{}) do
    GenServer.call(__MODULE__, {:plan, deployment_id, target, params})
  end

  def get_plan(deployment_id) do
    GenServer.call(__MODULE__, {:get_plan, deployment_id})
  end

  def list_infrastructure_projects do
    GenServer.call(__MODULE__, :list_projects)
  end

  @impl true
  def init(:ok) do
    {:ok, %{plans: %{}, projects: []}}
  end

  @impl true
  def handle_call({:plan, deployment_id, target, params}, _from, state) do
    network_topology = design_network(target, params)
    compute_requirements = plan_compute(target, params)
    storage_requirements = plan_storage(target, params)
    security_requirements = plan_security(target, params)

    plan = %{
      deployment_id: deployment_id,
      target: target,
      timestamp: DateTime.utc_now(),
      network: network_topology,
      compute: compute_requirements,
      storage: storage_requirements,
      security: security_requirements,
      estimated_setup_time_hours: calculate_setup_time(target, params)
    }

    {:reply, {:ok, plan},
     %{state | plans: Map.put(state.plans, deployment_id, plan),
               projects: [plan | state.projects]}}
  end

  def handle_call({:get_plan, deployment_id}, _from, state) do
    {:reply, Map.get(state.plans, deployment_id), state}
  end

  def handle_call(:list_projects, _from, state) do
    {:reply, state.projects, state}
  end

  defp design_network(:digital, params) do
    %{
      topology: :mesh,
      regions: params[:regions] || [:us_east, :us_west, :eu_west],
      load_balancer: true,
      cdn: true,
      vpc_config: %{subnets: 3, nat_gateway: true},
      bandwidth_gbps: length(params[:regions] || [:us_east]) * 10
    }
  end

  defp design_network(:physical, params) do
    %{
      topology: :star,
      gateway_protocol: :mqtt,
      edge_nodes: params[:edge_nodes] || 5,
      local_network: :ethernet,
      bandwidth_mbps: 100
    }
  end

  defp design_network(_, _params) do
    %{topology: :unknown, note: "Unknown target type"}
  end

  defp plan_compute(:digital, params) do
    instances = params[:instances] || 5
    %{
      compute_type: :kubernetes,
      node_pools: [
        %{name: :general, size: :medium, nodes: instances, cpu: 4, ram_gb: 16},
        %{name: :gpu, size: :large, nodes: 1, gpu: 1, cpu: 8, ram_gb: 32}
      ],
      auto_scaling: true,
      min_nodes: 3,
      max_nodes: instances * 2
    }
  end

  defp plan_compute(:physical, _params) do
    %{
      compute_type: :edge_processor,
      processors: [:arm_cortex_m7, :esp32],
      firmware_runtime: :bare_metal,
      watchdog_timer: true
    }
  end

  defp plan_compute(_, _params) do
    %{compute_type: :unknown, note: "Unknown target type"}
  end

  defp plan_storage(:digital, params) do
    %{
      database: :postgresql,
      replicas: 2,
      backup: :daily,
      retention_days: 90,
      object_storage: :s3_compatible,
      estimated_size_gb: params[:estimated_size_gb] || 100
    }
  end

  defp plan_storage(:physical, _params) do
    %{
      storage_type: :flash,
      capacity_mb: 512,
      wear_leveling: true,
      backup_to_cloud: true
    }
  end

  defp plan_storage(_, _params) do
    %{storage_type: :unknown}
  end

  defp plan_security(:digital, _params) do
    %{
      encryption: :aes256,
      tls: :v1_3,
      auth: :oauth2,
      firewall: :web_application_firewall,
      monitoring: :siem_integration,
      compliance: [:soc2, :gdpr]
    }
  end

  defp plan_security(:physical, _params) do
    %{
      encryption: :aes128,
      secure_boot: true,
      tamper_detection: true,
      physical_access_control: :required
    }
  end

  defp plan_security(_, _params) do
    %{encryption: :unknown_target}
  end

  defp calculate_setup_time(:digital, params) do
    base = 4
    regions = length(params[:regions] || [:us_east])
    base + (regions - 1) * 2
  end

  defp calculate_setup_time(:physical, params) do
    base = 8
    edge_nodes = params[:edge_nodes] || 5
    base + edge_nodes * 2
  end

  defp calculate_setup_time(_, _params) do
    0
  end
end
