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
  def handle_call({:validate, asset_id, evidence_bundle}, _from, state) do
    case Map.get(state.assets, asset_id) do
      nil -> {:reply, {:error, :not_found}, state}
      asset ->
        with {:ok, lineage} <- validate_lineage(asset, evidence_bundle),
             evidence when is_list(evidence) <- Map.get(evidence_bundle, :evidence, []),
             {:ok, confidence} <- validated_confidence(asset, evidence) do
          validated = %{asset |
            validation_status: :validated,
            confidence: confidence,
            contradictions: detect_contradictions(asset, evidence),
            verification_graph_ids: [lineage.graph_id],
            archive_ids: [lineage.archive_hash]
          }
          state = put_in(state, [:assets, asset_id], validated)
          {:reply, {:ok, validated}, state}
        else
          {:error, reason} -> {:reply, {:error, reason}, state}
          _ -> {:reply, {:error, :validation_requires_lineage}, state}
        end
    end
  end

  @impl true
  def handle_call({:get_assets, domain}, _from, state) do
    assets = state.assets
    |> Map.values()
    |> Enum.filter(&(&1.domain == domain and &1.validation_status == :validated))
    {:reply, assets, state}
  end

  defp validate_lineage(asset, %{lineage: %{graph_id: graph_id, archive_hash: archive_hash}}) do
    with :ok <- Tiannara.Sentinel.DiscoveryVerificationGraph.verify_chain(),
         :ok <- Tiannara.Sentinel.DiscoveryEvidenceArchive.verify(archive_hash),
         {:ok, node} <- Tiannara.Sentinel.DiscoveryVerificationGraph.get(graph_id),
         true <- Map.get(node, :discovery_id) == asset.discovery_id,
         true <- Map.get(node, :status) in [:reproduced, :operationally_validated] do
      {:ok, %{graph_id: graph_id, archive_hash: archive_hash}}
    else
      _ -> {:error, :validation_requires_verified_lineage}
    end
  end

  defp validate_lineage(_, _), do: {:error, :validation_requires_lineage}

  defp validated_confidence(asset, evidence) when is_list(evidence) do
    if evidence == [], do: {:error, :validation_evidence_required},
      else: {:ok, calculate_validated_confidence(asset, evidence)}
  end

  defp validated_confidence(_, _), do: {:error, :validation_evidence_required}

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
