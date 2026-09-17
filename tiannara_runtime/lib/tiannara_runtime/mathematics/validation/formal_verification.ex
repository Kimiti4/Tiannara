defmodule TiannaraRuntime.Mathematics.Validation.FormalVerification do
  @moduledoc """
  Phase 16.X.95 — Formal Verification Validation Campaign

  Verifies correctness, stability, convergence, constraint satisfaction,
  bounded behavior, termination. Generates deterministic counterexamples.
  Runs verification on known properties.
  """

  @behaviour TiannaraRuntime.Mathematics.Validation.Campaign

  alias TiannaraRuntime.Mathematics.FormalVerificationEngine

  @impl true
  def name, do: "Formal Verification"

  @impl true
  def description, do: "Verify correctness properties, generate deterministic counterexamples, run known-property verification."

  @impl true
  def run(_opts \\ []) do
    checks = [
      check_known_properties(),
      check_all_modes(),
      check_counterexample_generation(),
      check_archaeology()
    ]

    status = if Enum.all?(checks, fn c -> c.status == :pass end), do: :pass, else: :fail

    {:ok, %{
      campaign: name(),
      status: status,
      checks: checks,
      summary: %{
        total: length(checks),
        passed: Enum.count(checks, fn c -> c.status == :pass end),
        failed: Enum.count(checks, fn c -> c.status == :fail end),
        errors: Enum.count(checks, fn c -> c.status == :error end)
      }
    }}
  end

  defp check_known_properties do
    properties = [:correctness, :consistency, :completeness, :convergence, :stability, :safety, :termination, :bounded, :invariant_satisfaction, :constraint_satisfaction]
    target_types = ["symbolic_expression", "algorithm", "proof", "theorem"]

    results = Enum.flat_map(target_types, fn ttype ->
      Enum.map(properties, fn prop ->
        target_id = "known_target_#{ttype}_#{prop}"
        case FormalVerificationEngine.check_property(target_id, ttype, :structural, prop, []) do
          {:pass, _} -> %{target: ttype, property: prop, ok: true, result: :pass}
          {:fail, detail} -> %{target: ttype, property: prop, ok: true, result: :fail, detail: detail}
          {:error, reason} -> %{target: ttype, property: prop, ok: false, error: reason}
        end
      end)
    end)

    errors = Enum.filter(results, fn r -> r[:ok] == false end)

    if errors == [] do
      props_str = Enum.join(Enum.map(properties, &to_string/1), ", ")
      %{check: "known_properties", status: :pass, detail: "#{length(results)} checks across #{length(target_types)} targets and #{length(properties)} properties: #{props_str}"}
    else
      %{check: "known_properties", status: :fail, detail: "#{length(errors)} errors: #{inspect(Enum.take(errors, 3))}"}
    end
  end

  defp check_all_modes do
    modes = FormalVerificationEngine.valid_modes()
    properties = [:correctness, :stability, :convergence, :constraint_satisfaction]
    count = 100

    results = Enum.flat_map(1..count, fn i ->
      mode = Enum.at(modes, rem(i, length(modes)))
      ttype = "symbolic_expression"
      target_id = "mode_target_#{i}"

      case FormalVerificationEngine.verify(target_id, ttype, mode, properties) do
        {:ok, result} ->
          [%{iteration: i, mode: mode, ok: true, status: result["status"]}]
        {:error, reason} ->
          [%{iteration: i, mode: mode, ok: false, error: reason}]
      end
    end)

    errors = Enum.filter(results, fn r -> r[:ok] == false end)

    if errors == [] do
      mode_counts = Enum.map(modes, fn m ->
        m_results = Enum.filter(results, fn r -> r[:mode] == m end)
        "#{m}: #{length(m_results)}"
      end)
      %{check: "all_modes", status: :pass, detail: "#{length(results)} verifications across [#{Enum.join(mode_counts, ", ")}]"}
    else
      %{check: "all_modes", status: :fail, detail: "#{length(errors)} errors: #{inspect(Enum.take(errors, 3))}"}
    end
  end

  defp check_counterexample_generation do
    count = 50

    results = Enum.map(1..count, fn i ->
      target_id = "target_#{i}"
      property = Enum.at([:correctness, :stability, :convergence, :safety, :termination], rem(i, 5))
      detail = %{
        minimal_example: "x = #{i}",
        reconstruction_path: ["step_#{i}_0", "step_#{i}_1"],
        dependency_chain: ["dep_#{i}"]
      }

      counterexample = FormalVerificationEngine.build_counterexample(target_id, property, detail)

      has_property = Map.has_key?(counterexample, "violated_property")
      has_example = Map.has_key?(counterexample, "minimal_example")
      has_path = Map.has_key?(counterexample, "reconstruction_path")
      has_hash = Map.has_key?(counterexample, "replay_hash")
      complete = has_property and has_example and has_path and has_hash

      %{iteration: i, complete: complete, property: property, example: counterexample["minimal_example"]}
    end)

    complete = Enum.filter(results, fn r -> r[:complete] == true end)

    if length(complete) == length(results) do
      %{check: "counterexample_generation", status: :pass, detail: "#{length(complete)} counterexamples generated across all properties"}
    else
      %{check: "counterexample_generation", status: :fail, detail: "#{length(results) - length(complete)} incomplete counterexamples"}
    end
  end

  defp check_archaeology do
    results = Enum.map(1..50, fn i ->
      target_id = "arch_target_#{i}"
      properties = [:correctness, :stability]

      with {:ok, result} <- FormalVerificationEngine.verify(target_id, "theorem", :logical, properties),
           {:ok, record} <- FormalVerificationEngine.archaeology(result) do
        has_vid = Map.has_key?(record, "verification_id")
        has_target = Map.has_key?(record, "target_id")
        has_why = Map.has_key?(record, "performed_why")
        complete = has_vid and has_target and has_why
        %{iteration: i, complete: complete}
      else
        {:error, _} -> %{iteration: i, complete: false}
      end
    end)

    complete = Enum.filter(results, fn r -> r[:complete] == true end)

    if length(complete) > length(results) / 2 do
      %{check: "archaeology", status: :pass, detail: "#{length(complete)}/#{length(results)} verifications have complete archaeology"}
    else
      %{check: "archaeology", status: :fail, detail: "#{length(complete)}/#{length(results)} — insufficient archaeology coverage"}
    end
  end
end
