defmodule Tiannara.ASC.Memory.InstitutionalMemory do
  @moduledoc """
  Phase 11: Long-Horizon Memory.
  Persists Architectural Decision Records (ADRs), Technical Debt, and 
  Product Vision to the physical repository, ensuring knowledge survives 
  across months of development and agent turnover.
  """
  require Logger

  @adr_path "docs/architecture/decisions/"
  @debt_path "docs/technical_debt.ndjson"

  @doc """
  Records a major architectural decision and the tradeoffs rejected.
  """
  def record_adr(title, context, decision, rejected_alternatives) do
    adr_id = generate_adr_id()
    filename = "#{adr_id}-#{slugify(title)}.md"
    
    content = """
    # ADR #{adr_id}: #{title}
    
    ## Context
    #{context}
    
    ## Decision
    #{decision}
    
    ## Rejected Alternatives
    #{Enum.map_join(rejected_alternatives, "\n", & "- #{&1}")}
    
    ## Status
    Accepted (#{Date.utc_today()})
    """
    
    File.mkdir_p!(@adr_path)
    File.write!(Path.join(@adr_path, filename), content)
    Logger.info("🧠 [InstitutionalMemory] Recorded ADR #{adr_id}: #{title}")
    {:ok, adr_id}
  end
  @doc """
  Logs technical debt incurred during a mission to prevent infinite accumulation.
  """
  def log_tech_debt(mission_id, description, severity) do
    entry = %{
      timestamp: System.system_time(:millisecond),
      mission_id: mission_id,
      description: description,
      severity: severity
    }
    
    File.mkdir_p!(Path.dirname(@debt_path))
    File.write!(@debt_path, Jason.encode!(entry) <> "\n", [:append])
    Logger.warning("⚠️ [InstitutionalMemory] Logged Tech Debt (Severity: #{severity}): #{description}")
  end

  @doc """
  Phase 16: Retrieve all ADRs for Epistemic Immune System scanning.
  """
  def get_all_adrs do
    if File.exists?(@adr_path) do
      @adr_path
      |> File.ls!()
      |> Enum.filter(&String.ends_with?(&1, ".md"))
      |> Enum.map(fn filename -> 
        path = Path.join(@adr_path, filename)
        content = File.read!(path)
        # Extract ID from filename "20260401-slug.md"
        [id | _] = String.split(filename, "-")
        %{id: id, filename: filename, content: content}
      end)
    else
      []
    end
  end

  def get_relevant_adrs(_goal), do: get_all_adrs()

  @doc """
  Phase 16: Flag an ADR as corrupted (Quarantine Protocol).
  """
  def flag_as_corrupted(adr_id) do
    adrs = get_all_adrs()
    case Enum.find(adrs, &(&1.id == adr_id)) do
      nil -> Logger.error("Could not find ADR #{adr_id} to flag as corrupted.")
      adr ->
        path = Path.join(@adr_path, adr.filename)
        warning = "\n\n> [!WARNING]\n> **IMMUNE SYSTEM QUARANTINE**: This ADR has been flagged for Reality Drift. Its contents contradict the physical codebase.\n"
        File.write!(path, adr.content <> warning)
    end
  end
  @fossil_record_path "docs/ecology/fossil_record.ndjson"

  @doc """
  Phase 15: Records an extinct capability so the civilization learns from the failure.
  """
  def record_rejected_hypothesis(capability_name, reason) do
    entry = %{
      timestamp: System.system_time(:millisecond),
      type: :extinct_capability,
      name: capability_name,
      reason: reason
    }
    
    File.mkdir_p!(Path.dirname(@fossil_record_path))
    File.write!(@fossil_record_path, Jason.encode!(entry) <> "\n", [:append])
    Logger.info("🦴 [FossilRecord] Buried '#{capability_name}' in the Institutional Memory.")
  end

  def get_fossil_record do
    if File.exists?(@fossil_record_path) do
      @fossil_record_path
      |> File.stream!()
      |> Enum.map(&Jason.decode!/1)
    else
      []
    end
  end

  defp generate_adr_id, do: DateTime.utc_now() |> Calendar.strftime("%Y%m%d%H%M")
  defp slugify(str), do: str |> String.downcase() |> String.replace(~r/\s+/, "-")
end
