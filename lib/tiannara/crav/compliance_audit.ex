defmodule Tiannara.CRAV.ComplianceAudit do
  @moduledoc """
  Phase Ω+ CRAV Deliverable 13 — Compliance Audit.

  Audits each registered subsystem against the seven constitutional
  dimensions: constitutional, mission-aligned, safe, replayable,
  explainable, evidence-based, and evolving.
  """

  require Logger

  alias Tiannara.PhaseOmega.SubsystemRegistry

  @telemetry_event [:tiannara, :crav, :compliance, :audited]

  @discovery_subsystems MapSet.new([
    :discovery_pipeline, :rea, :knowledge_graph, :observatory,
    :theory_ecology, :epistemic_mirror, :nde
  ])

  @type audit_result :: %{
    name: atom(),
    constitutional: boolean(),
    mission_aligned: boolean(),
    safe: boolean(),
    replayable: boolean(),
    explainable: boolean(),
    evidence_based: boolean(),
    evolving: boolean(),
    compliance_score: float()
  }

  @spec audit() :: {:ok, [audit_result()]} | {:error, term()}
  def audit do
    try do
      records = fetch_subsystems()

      entries =
        Enum.map(records, fn record ->
          mod = record.module
          name = record.name

          constitutional = check_constitutional(mod)
          mission_aligned = check_mission_aligned(record)
          safe = check_safe(mod)
          replayable = check_replayable(mod)
          explainable = check_explainable(mod)
          evidence_based = check_evidence_based(mod, name)
          evolving = check_evolving(record)

          checks = [constitutional, mission_aligned, safe, replayable, explainable, evidence_based, evolving]
          passing = Enum.count(checks, & &1)

          %{
            name: name,
            constitutional: constitutional,
            mission_aligned: mission_aligned,
            safe: safe,
            replayable: replayable,
            explainable: explainable,
            evidence_based: evidence_based,
            evolving: evolving,
            compliance_score: Float.round(passing / 7, 4)
          }
        end)

      total = length(entries)
      compliant = Enum.count(entries, &(&1.compliance_score >= 1.0))

      :telemetry.execute(
        @telemetry_event,
        %{
          total_audited: total,
          compliant: compliant,
          non_compliant: total - compliant,
          overall: compute_overall(entries)
        },
        %{timestamp: DateTime.utc_now()}
      )

      {:ok, entries}
    rescue
      err -> {:error, {:compliance_audit_failed, err}}
    catch
      kind, reason -> {:error, {:compliance_audit_crashed, kind, reason}}
    end
  end

  @spec non_compliant() :: {:ok, [audit_result()]} | {:error, term()}
  def non_compliant do
    case audit() do
      {:ok, entries} ->
        {:ok, Enum.filter(entries, &(&1.compliance_score < 1.0))}

      err ->
        err
    end
  end

  @spec compliance_report() :: {:ok, String.t()} | {:error, term()}
  def compliance_report do
    case audit() do
      {:ok, entries} ->
        now = DateTime.utc_now()
        total = length(entries)
        compliant = Enum.count(entries, &(&1.compliance_score >= 1.0))
        non = total - compliant
        overall = compute_overall(entries)

        lines =
          [
            "═══════════════════════════════════════════════════════",
            "  CRAV COMPLIANCE AUDIT — #{DateTime.to_iso8601(now)}",
            "═══════════════════════════════════════════════════════",
            "  Total: #{total}  |  Compliant: #{compliant}  |  Non-Compliant: #{non}",
            "  Overall Compliance: #{Float.round(overall * 100, 1)}%",
            "───────────────────────────────────────────────────────"
          ] ++
            Enum.map(entries, fn e ->
              name_str = e.name |> format_name() |> String.pad_trailing(30)
              score_str = e.compliance_score |> Float.round(2) |> to_string() |> String.pad_leading(5)

              flags =
                [
                  {e.constitutional, "C"},
                  {e.mission_aligned, "M"},
                  {e.safe, "S"},
                  {e.replayable, "R"},
                  {e.explainable, "E"},
                  {e.evidence_based, "V"},
                  {e.evolving, "G"}
                ]
                |> Enum.map(fn {pass, label} -> if pass, do: label, else: "-" end)
                |> Enum.join("")

              "  #{name_str} #{score_str}  [#{flags}]"
            end) ++
            ["═══════════════════════════════════════════════════════"]

        {:ok, Enum.join(lines, "\n")}

      err ->
        err
    end
  end

  @spec overall_compliance() :: {:ok, float()} | {:error, term()}
  def overall_compliance do
    case audit() do
      {:ok, entries} -> {:ok, compute_overall(entries)}
      err -> err
    end
  end

  defp compute_overall([]), do: 0.0

  defp compute_overall(entries) do
    scores = Enum.map(entries, & &1.compliance_score)
    Float.round(min(1.0, max(0.0, Enum.sum(scores) / length(scores))), 4)
  end

  defp check_constitutional(mod) do
    module_available?(mod) and has_documentation?(mod) and follows_otp_pattern?(mod)
  end

  defp check_mission_aligned(record) do
    record.name != nil and record.module != nil
  end

  defp check_safe(mod) do
    cond do
      not module_available?(mod) -> true
      contains_unsafe_operations?(mod) -> false
      true -> true
    end
  end

  defp check_replayable(mod) do
    module_available?(mod) and emits_telemetry?(mod)
  end

  defp check_explainable(mod) do
    has_documentation?(mod)
  end

  defp check_evidence_based(mod, name) do
    cond do
      not module_available?(mod) -> false
      MapSet.member?(@discovery_subsystems, name) -> true
      beam_references?(mod, "discovery") -> true
      beam_references?(mod, "knowledge") -> true
      true -> false
    end
  end

  defp check_evolving(record) do
    case record.last_activity do
      nil ->
        false

      %DateTime{} = dt ->
        DateTime.diff(DateTime.utc_now(), dt, :second) < 72 * 60 * 60

      _ ->
        false
    end
  end

  defp module_available?(nil), do: false

  defp module_available?(mod) when is_atom(mod) do
    Code.ensure_loaded?(mod)
  end

  defp module_available?(_), do: false

  defp has_documentation?(mod) do
    try do
      case Code.fetch_docs(mod) do
        {:docs_v1, _, _, _, %{"en" => doc}, _, _} when is_binary(doc) ->
          String.trim(doc) != ""

        _ ->
          false
      end
    rescue
      _ -> false
    catch
      _, _ -> false
    end
  end

  defp follows_otp_pattern?(mod) do
    has_otp_functions?(mod) or implements_behaviour?(mod)
  end

  defp has_otp_functions?(mod) do
    try do
      functions = mod.__info__(:functions)

      Enum.any?(functions, fn {name, _arity} ->
        name in [:start_link, :start, :child_spec]
      end)
    rescue
      _ -> false
    catch
      _, _ -> false
    end
  end

  defp implements_behaviour?(mod) do
    try do
      behaviours =
        mod.module_info(:attributes)
        |> Keyword.get_values(:behaviour)
        |> List.flatten()

      Enum.any?(behaviours, fn
        GenServer -> true
        Supervisor -> true
        :gen_server -> true
        :supervisor -> true
        _ -> false
      end)
    rescue
      _ -> false
    catch
      _, _ -> false
    end
  end

  defp contains_unsafe_operations?(mod) do
    try do
      case :beam_lib.chunks(mod, [:abstract_code]) do
        {:ok, {^mod, [{:abstract_code, {:raw_abstract_v1, forms}}]}} ->
          bin = :erlang.term_to_binary(forms)

          Enum.any?(["rm!", "rm_rf!"], fn pattern ->
            :binary.match(bin, pattern) != :nomatch
          end)

        _ ->
          false
      end
    rescue
      _ -> false
    catch
      _, _ -> false
    end
  end

  defp emits_telemetry?(mod) do
    has_telemetry_functions?(mod) or beam_references?(mod, "telemetry")
  end

  defp has_telemetry_functions?(mod) do
    try do
      functions = mod.__info__(:functions)

      Enum.any?(functions, fn {name, _arity} ->
        str = Atom.to_string(name)

        String.contains?(str, "emit") or
          String.contains?(str, "publish") or
          String.contains?(str, "telemetry") or
          String.contains?(str, "broadcast")
      end)
    rescue
      _ -> false
    catch
      _, _ -> false
    end
  end

  defp beam_references?(mod, pattern) do
    try do
      case :beam_lib.chunks(mod, [:abstract_code]) do
        {:ok, {^mod, [{:abstract_code, {:raw_abstract_v1, forms}}]}} ->
          bin = :erlang.term_to_binary(forms)
          :binary.match(bin, pattern) != :nomatch

        _ ->
          false
      end
    rescue
      _ -> false
    catch
      _, _ -> false
    end
  end

  defp fetch_subsystems do
    try do
      if Code.ensure_loaded?(SubsystemRegistry) and Process.whereis(SubsystemRegistry) do
        SubsystemRegistry.all()
      else
        []
      end
    rescue
      _ -> []
    catch
      _, _ -> []
    end
  end

  defp format_name(name) when is_atom(name), do: name |> Atom.to_string() |> String.upcase()
  defp format_name(name), do: to_string(name) |> String.upcase()
end
