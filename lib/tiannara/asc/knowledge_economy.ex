defmodule Tiannara.ASC.KnowledgeEconomy do
  @moduledoc """
  Governs the lifecycle of knowledge from discovery to civilizational asset.
  Pipeline: Discovery → Validation → Integration → Reuse → Capability Improvement
  """
  use GenServer
  alias Tiannara.ASC.Models.KnowledgeAsset

  def start_link(opts \\ []), do: GenServer.start_link(__MODULE__, %{}, opts)

  def ingest_discovery(pid, discovery), do: GenServer.call(pid, {:ingest, discovery})
  def validate_asset(pid, asset_id, evidence), do: GenServer.call(pid, {:validate, asset_id, evidence})
  def get_assets(pid, domain), do: GenServer.call(pid, {:get_assets, domain})

  @impl true
  def init(_), do: {:ok, %{assets: %{}, reuse_index: %{}}}

  @impl true
  def handle_call({:ingest, discovery}, _from, state) do
    asset = %KnowledgeAsset{
      id: UUID.uuid4(),
      discovery_id: discovery.id,
      domain: discovery.domain,
      content: discovery.content,
      validation_status: :pending_validation,
      confidence: discovery.confidence || 0.5,
      created_at: DateTime.utc_now()
    }
    state = put_in(state, [:assets, asset.id], asset)
    {:reply, {:ok, asset}, state}
  end

  @impl true
  def handle_call({:validate, asset_id, evidence}, _from, state) do
    case Map.get(state.assets, asset_id) do
      nil -> {:reply, {:error, :not_found}, state}
      asset ->
        validated = %{asset |
          validation_status: :validated,
          confidence: calculate_validated_confidence(asset, evidence),
          contradictions: detect_contradictions(asset, evidence)
        }
        state = put_in(state, [:assets, asset_id], validated)
        {:reply, {:ok, validated}, state}
    end
  end

  @impl true
  def handle_call({:get_assets, domain}, _from, state) do
    assets = state.assets
    |> Map.values()
    |> Enum.filter(&(&1.domain == domain and &1.validation_status == :validated))
    {:reply, assets, state}
  end

  defp calculate_validated_confidence(asset, evidence) do
    net = Enum.reduce(evidence, 0, fn e, acc ->
      if e.contradicts_asset == asset.id do
        acc - e.quality * 0.3
      else
        acc + e.quality * 0.3
      end
    end)
    max(0.05, min(1.0, asset.confidence + net))
  end

  defp detect_contradictions(asset, evidence) do
    Enum.filter(evidence, & &1.contradicts_asset == asset.id)
    |> Enum.map(& &1.id)
  end
end
