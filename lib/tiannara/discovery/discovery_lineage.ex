defmodule Tiannara.Discovery.DiscoveryLineage do
  alias Tiannara.Discovery.Discovery

  @doc """
  Returns the full lineage trace for a discovery.
  """
  @spec trace(Discovery.t()) :: [map()]
  def trace(%Discovery{lineage: lineage}), do: lineage

  @doc """
  Returns ancestry events (creation, promotion, completion).
  """
  @spec ancestry(Discovery.t()) :: [map()]
  def ancestry(%Discovery{lineage: lineage}) do
    lineage |> Enum.filter(fn e -> e.event in [:discovery_created, :knowledge_promoted, :discovery_completed] end)
  end

  @doc """
  Returns hypothesis evolution events.
  """
  @spec hypothesis_evolution(Discovery.t()) :: [map()]
  def hypothesis_evolution(%Discovery{lineage: lineage}) do
    lineage |> Enum.filter(fn e -> e.event in [:hypotheses_added, :evidence_added, :conclusion_reached] end)
  end

  @doc """
  Returns the unique path of events in chronological order.
  """
  @spec discovery_path(Discovery.t()) :: [atom()]
  def discovery_path(%Discovery{lineage: lineage}) do
    lineage |> Enum.map(fn e -> e.event end) |> Enum.uniq()
  end

  @doc """
  Builds a provenance tree showing the lineage as a nested structure with integrity metadata.
  """
  @spec provenance_tree(Discovery.t()) :: map()
  def provenance_tree(%Discovery{} = discovery) do
    integrity = verify_integrity(discovery)

    %{
      discovery_id: discovery.id,
      root: %{
        event: :discovery_created,
        from_gap: discovery.gap.id,
        timestamp: discovery.created_at
      },
      branches: build_branches(discovery.lineage, discovery),
      leaf: %{
        status: discovery.status,
        event: if(Discovery.terminal?(discovery), do: :discovery_completed, else: :in_progress),
        timestamp: discovery.updated_at
      },
      integrity: integrity,
      integrity_hash: calculate_integrity_hash(discovery.lineage)
    }
  end

  @doc """
  Verifies the integrity of a discovery's lineage.
  Returns :ok or {:error, list of violation descriptions}.
  """
  @spec verify_integrity(Discovery.t()) :: :ok | {:error, [String.t()]}
  def verify_integrity(%Discovery{} = discovery) do
    violations = []
    violations = if discovery.lineage == [], do: ["empty lineage" | violations], else: violations
    violations = if discovery.status in [:completed, :abandoned] and
                    not lineage_has_terminal_event?(discovery.lineage),
      do: ["terminal status but no terminal lineage event" | violations], else: violations
    violations = if discovery.created_at && discovery.updated_at &&
                    DateTime.compare(discovery.updated_at, discovery.created_at) == :lt,
      do: ["updated_at before created_at" | violations], else: violations
    violations = verify_event_ordering(discovery.lineage, violations)
    if violations == [], do: :ok, else: {:error, Enum.reverse(violations)}
  end

  @doc """
  Checks lineage integrity, returning atoms instead of strings for violations.
  Returns :ok or {:error, list of atom violations}.
  """
  @spec check_integrity(Discovery.t()) :: :ok | {:error, [atom()]}
  def check_integrity(%Discovery{} = discovery) do
    violations = []
    violations = if discovery.gap == nil, do: [:missing_gap | violations], else: violations
    violations = if discovery.lineage == [], do: [:empty_lineage | violations], else: violations
    violations = if discovery.status in [:completed, :abandoned] and
                    not lineage_has_terminal_event?(discovery.lineage),
      do: [:missing_terminal_event | violations], else: violations
    violations = if discovery.created_at && discovery.updated_at &&
                    DateTime.compare(discovery.updated_at, discovery.created_at) == :lt,
      do: [:timestamp_inversion | violations], else: violations
    if violations == [], do: :ok, else: {:error, Enum.reverse(violations)}
  end

  @doc """
  Returns a concise summary of the discovery including integrity information.
  """
  @spec summarize(Discovery.t()) :: map()
  def summarize(%Discovery{} = discovery) do
    integrity_status = case verify_integrity(discovery) do
      :ok -> :valid
      {:error, _} -> :compromised
    end

    %{
      id: discovery.id,
      question: discovery.question,
      status: discovery.status,
      confidence: discovery.confidence,
      score: discovery.score,
      steps: length(discovery.lineage),
      hypotheses: length(discovery.hypotheses),
      experiments: length(discovery.experiments),
      evidence: length(discovery.evidence),
      integrity: integrity_status,
      terminal: Discovery.terminal?(discovery)
    }
  end

  defp build_branches(lineage, discovery) do
    lineage
    |> Enum.group_by(fn e -> Map.get(e, :from, discovery.gap.domain) end)
    |> Enum.map(fn {domain, events} ->
      %{domain: domain, event_count: length(events),
        events: Enum.map(events, fn e -> %{event: e.event, timestamp: e.at} end)}
    end)
  end

  defp calculate_integrity_hash(lineage) do
    representation = lineage |> Enum.map(fn e -> "#{e.event}_#{inspect(Map.get(e, :at, :none))}" end) |> Enum.join("|")
    :crypto.hash(:sha256, representation) |> Base.encode16(case: :lower)
  end

  defp lineage_has_terminal_event?(lineage) do
    Enum.any?(lineage, fn e -> e.event in [:discovery_completed, :discovery_abandoned] end)
  end

  defp verify_event_ordering([], violations), do: violations
  defp verify_event_ordering([_], violations), do: violations
  defp verify_event_ordering([a, b | rest], violations) do
    violations = if Map.has_key?(a, :at) and Map.has_key?(b, :at) and
                    DateTime.compare(b.at, a.at) == :lt,
      do: ["lineage events out of order at #{inspect(b.event)}" | violations],
      else: violations
    verify_event_ordering([b | rest], violations)
  end
end
