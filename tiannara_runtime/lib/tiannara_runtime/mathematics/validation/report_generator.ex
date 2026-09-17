defmodule TiannaraRuntime.Mathematics.Validation.ReportGenerator do
  @moduledoc """
  Phase 16.X.95 — Validation Report Generator

  Generates all 11 deliverable reports for the Constitutional Mathematics
  Validation Campaign. Reports are written as markdown (or JSON for the
  machine-readable summary) to `priv/validation_reports/`.
  """

  @report_dir "priv/validation_reports"

  @doc "Generate the top-level MATHEMATICS_VALIDATION_REPORT.md"
  @spec generate_validation_report(map()) :: :ok
  def generate_validation_report(validation) do
    content = """
    # Mathematics Validation Report
    **Phase 16.X.95 — Constitutional Mathematics Validation Campaign**

    ## Overview

    | Field            | Value                         |
    |------------------|-------------------------------|
    | Campaign         | Mathematics Validation        |
    | Status           | #{status_badge(validation.status)}                          |
    | Total Campaigns  | #{map_size(validation.results)}                             |
    | Generated        | #{timestamp()}                |

    ## Campaign Results

    #{campaign_results_table(validation)}

    ## Aggregate Metrics

    #{aggregate_metrics_section(validation)}

    ## Failures

    #{failures_section(validation)}
    """

    write_report("MATHEMATICS_VALIDATION_REPORT.md", content)
  end

  @doc "Generate CONTRACT_VALIDATION_REPORT.md"
  @spec generate_contract_report(map()) :: :ok
  def generate_contract_report(validation) do
    content = campaign_report_template(
      "Contract Validation",
      :contract,
      validation,
      "Validates that all mathematical contracts are well-formed, complete, and constitutionally sound."
    )
    write_report("CONTRACT_VALIDATION_REPORT.md", content)
  end

  @doc "Generate MATHEMATICS_REPLAY_REPORT.md"
  @spec generate_replay_report(map()) :: :ok
  def generate_replay_report(validation) do
    content = campaign_report_template(
      "Mathematics Replay",
      :replay,
      validation,
      "Replays every proof from its canonical representation to verify deterministic reconstruction."
    )
    write_report("MATHEMATICS_REPLAY_REPORT.md", content)
  end

  @doc "Generate SERIALIZATION_REPORT.md"
  @spec generate_serialization_report(map()) :: :ok
  def generate_serialization_report(validation) do
    content = campaign_report_template(
      "Serialization Validation",
      :serialization,
      validation,
      "Validates that all mathematical objects survive round-trip serialization/deserialization without data loss."
    )
    write_report("SERIALIZATION_REPORT.md", content)
  end

  @doc "Generate PROOF_VALIDATION_REPORT.md"
  @spec generate_proof_report(map()) :: :ok
  def generate_proof_report(validation) do
    content = campaign_report_template(
      "Proof Validation",
      :proof,
      validation,
      "Verifies each proof step against the constitutional axioms and proof strategies."
    )
    write_report("PROOF_VALIDATION_REPORT.md", content)
  end

  @doc "Generate CONJECTURE_VALIDATION_REPORT.md"
  @spec generate_conjecture_report(map()) :: :ok
  def generate_conjecture_report(validation) do
    content = campaign_report_template(
      "Conjecture Validation",
      :conjecture,
      validation,
      "Validates the conjecture lifecycle: generation, ranking, evidence tracking, and status transitions."
    )
    write_report("CONJECTURE_VALIDATION_REPORT.md", content)
  end

  @doc "Generate VERIFICATION_REPORT.md"
  @spec generate_verification_report(map()) :: :ok
  def generate_verification_report(validation) do
    content = campaign_report_template(
      "Verification Report",
      :verification,
      validation,
      "Formal verification of mathematical statements against the constitutional framework."
    )
    write_report("VERIFICATION_REPORT.md", content)
  end

  @doc "Generate RUNTIME_VALIDATION_REPORT.md"
  @spec generate_runtime_report(map()) :: :ok
  def generate_runtime_report(validation) do
    content = campaign_report_template(
      "Runtime Validation",
      :runtime,
      validation,
      "End-to-end validation of the Mathematics Runtime: scheduling, execution, and monitoring."
    )
    write_report("RUNTIME_VALIDATION_REPORT.md", content)
  end

  @doc "Generate STRESS_REPORT.md"
  @spec generate_stress_report(map()) :: :ok
  def generate_stress_report(validation) do
    content = campaign_report_template(
      "Stress Report",
      :stress,
      validation,
      "Stress tests the mathematical subsystems under high load, concurrent access, and large proofs."
    )
    write_report("STRESS_REPORT.md", content)
  end

  @doc "Generate FAILURE_INJECTION_REPORT.md"
  @spec generate_failure_injection_report(map()) :: :ok
  def generate_failure_injection_report(validation) do
    content = campaign_report_template(
      "Failure Injection Report",
      :failure_injection,
      validation,
      "Injects failures into subsystems and validates graceful degradation and error recovery."
    )
    write_report("FAILURE_INJECTION_REPORT.md", content)
  end

  @doc "Generate ARCHAEOLOGY_VALIDATION_REPORT.md"
  @spec generate_archaeology_report(map()) :: :ok
  def generate_archaeology_report(validation) do
    content = campaign_report_template(
      "Archaeology Validation",
      :archaeology,
      validation,
      "Validates the archaeological subsystem: provenance recording, reconstruction, and explanation."
    )
    write_report("ARCHAEOLOGY_VALIDATION_REPORT.md", content)
  end

  @doc "Generate PHASE16X_VALIDATION_SUMMARY.json"
  @spec generate_summary_json(map()) :: :ok
  def generate_summary_json(validation) do
    summary = %{
      phase: "16.X.95",
      campaign: "Constitutional Mathematics Validation Campaign",
      generated_at: timestamp(),
      status: validation.status,
      total_campaigns: map_size(validation.results),
      campaigns:
        Enum.map(validation.results, fn {name, result} ->
          %{
            name: name,
            status: Map.get(result, :status, :error),
            error: Map.get(result, :error),
            metrics: Map.get(result, :metrics, %{})
          }
        end),
      aggregate_metrics: validation.metrics
    }

    json = Jason.encode!(summary, pretty: true)
    write_report("PHASE16X_VALIDATION_SUMMARY.json", json)
  end

  # ---------------------------------------------------------------------------
  # Private helpers
  # ---------------------------------------------------------------------------

  defp campaign_report_template(title, campaign_key, validation, description) do
    result = Map.get(validation.results, campaign_key, %{status: :not_run})
    status = Map.get(result, :status, :not_run)
    error = Map.get(result, :error)
    metrics = Map.get(result, :metrics, %{})
    duration = Map.get(metrics, :duration_ms, "N/A")

    failures =
      case Map.get(result, :failures, []) do
        [] -> "  - None"
        list -> Enum.map_join(list, "\n", fn f -> "  - #{f}" end)
      end

    """
    ## #{title}

    **Campaign:** #{campaign_key}
    **Status:** #{status_badge(status)}
    **Duration:** #{duration} ms
    **Description:** #{description}

    ### Metrics

    #{format_metrics(metrics)}

    ### Failures

    #{failures}
    """
  end

  defp campaign_results_table(validation) do
    rows =
      Enum.map(validation.results, fn {name, result} ->
        status = Map.get(result, :status, :error)
        "| #{name} | #{status_badge(status)} |"
      end)

    """
    | Campaign          | Status  |
    |-------------------|---------|
    #{Enum.join(rows, "\n")}
    """
  end

  defp aggregate_metrics_section(validation) do
    if map_size(validation.metrics) == 0 do
      "  - No metrics collected."
    else
      Enum.map_join(validation.metrics, "\n", fn {campaign, metrics} ->
        "  - **#{campaign}**: #{format_metrics_inline(metrics)}"
      end)
    end
  end

  defp failures_section(validation) do
    failed_campaigns =
      Enum.filter(validation.results, fn {_name, r} ->
        Map.get(r, :status) in [:fail, :error]
      end)

    case failed_campaigns do
      [] -> "  - No failures detected."
      list ->
        Enum.map_join(list, "\n", fn {name, r} ->
          error = Map.get(r, :error, "Unknown failure")
          "  - **#{name}**: #{error}"
        end)
    end
  end

  defp format_metrics(metrics) when map_size(metrics) == 0 do
    "  - No metrics recorded."
  end

  defp format_metrics(metrics) do
    Enum.map_join(metrics, "\n", fn {key, val} ->
      "  - **#{key}**: #{val}"
    end)
  end

  defp format_metrics_inline(metrics) when map_size(metrics) == 0, do: "no metrics"

  defp format_metrics_inline(metrics) do
    metrics
    |> Enum.map(fn {k, v} -> "#{k}: #{v}" end)
    |> Enum.join(", ")
  end

  defp status_badge(:pass), do: "✅ PASS"
  defp status_badge(:fail), do: "❌ FAIL"
  defp status_badge(:error), do: "💥 ERROR"
  defp status_badge(_), do: "⏭️  NOT RUN"

  defp timestamp do
    :erlang.unique_integer([:positive]) |> Integer.to_string()
  end

  defp write_report(filename, content) do
    path = Path.join(@report_dir, filename)
    File.mkdir_p!(@report_dir)
    File.write!(path, content)
    path
  end
end
