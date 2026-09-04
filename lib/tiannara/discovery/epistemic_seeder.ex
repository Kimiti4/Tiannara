defmodule Tiannara.Discovery.EpistemicSeeder do
  @moduledoc """
  Stage 2 of the instrument-first build: epistemic pressure.

  Seeds the world model with four provenance-tagged entities
  (`origin: :epistemic_seed`) that carry legitimate epistemic tension:

    * A high-confidence observation A
    * An observation B that contradicts A
    * A stale-theory observation with an outdated evidence chain
    * A low-confidence observation

  The seeds are INPUTS, never earned discoveries: the manifest records
  exactly what was injected (`entities_created`, `gaps_from_seed`,
  `contradictions_from_seed`) side by side with later pipeline telemetry so
  the absorbing stage of the pressure can be located.

  The report fed to `GapAnalyzer`/`ContradictionAnalyzer` is computed from
  the seeded subset only, so failures cannot skew the pressure signal.
  """

  require Logger

  alias Tiannara.Discovery.{ContradictionAnalyzer, GapAnalyzer}
  alias Tiannara.World.UnifiedWorldModel
  alias Tiannara.Storage.Paths

  @seed_names [:seed_obs_a, :seed_obs_b, :seed_stale, :seed_lowconf]

  @doc """
  Runs the seed battery for `:domain` (default `:sensor_fusion`) and returns
  the manifest. Safe to call repeatedly; each run stamps fresh entity ids.
  """
  def seed_battery(opts \\ []) do
    domain = Keyword.get(opts, :domain, :sensor_fusion)
    specs = seed_specs(domain)

    results =
      Enum.map(specs, fn spec ->
        {spec.name, spec.id, UnifiedWorldModel.create_entity(spec.spec)}
      end)

    created = Enum.filter(results, fn {_name, _id, r} -> match?({:ok, _}, r) end)
    failures = Enum.filter(results, fn {_name, _id, r} -> not match?({:ok, _}, r) end)

    report = build_report(domain, specs, created)
    gaps = safe_gaps(report)
    contradictions = safe_contradictions(domain, created)

    manifest = %{
      domain: domain,
      entities_created: length(created),
      entity_ids: Enum.map(created, fn {_name, id, _r} -> id end),
      entity_failures:
        Enum.map(failures, fn {name, id, r} -> %{name: name, id: id, reason: inspect(r)} end),
      gaps_from_seed: Enum.map(gaps, &Map.get(&1, :id, "gap_#{inspect(Map.get(&1, :domain))}")),
      contradictions_from_seed:
        Enum.map(contradictions, &Map.get(&1, :description, "contradiction")),
      note:
        "Seeded entities are epistemic INPUTS (provenance origin=:epistemic_seed), not earned discoveries. Compare pipeline counters before/after to locate the absorbing stage.",
      seeded_at: DateTime.utc_now()
    }

    persist_manifest(manifest)
    manifest
  end

  @doc "The most recent manifest, or nil if the seeder has never run."
  def last_manifest do
    case File.read(manifest_file()) do
      {:ok, contents} ->
        case Jason.decode(contents) do
          {:ok, decoded} -> decoded
          _ -> nil
        end

      _ ->
        nil
    end
  end

  defp seed_specs(domain) do
    stamp = :crypto.strong_rand_bytes(4) |> Base.encode16(case: :lower)

    [
      %{
        name: :seed_obs_a,
        id: "seed_obs_a_#{stamp}",
        spec: %{
          id: "seed_obs_a_#{stamp}",
          type: :fact,
          subtype: :observation,
          domain: domain,
          attributes: %{
            property: "sensor_fusion_reading",
            value: "signal",
            note: "Seeded observation A — high confidence reading"
          },
          confidence: 0.85,
          provenance: %{
            origin: :epistemic_seed,
            actor: :epistemic_seeder,
            note: "Battery A — signal reading"
          }
        }
      },
      %{
        name: :seed_obs_b,
        id: "seed_obs_b_#{stamp}",
        spec: %{
          id: "seed_obs_b_#{stamp}",
          type: :fact,
          subtype: :observation,
          domain: domain,
          attributes: %{
            property: "sensor_fusion_reading",
            value: "noise",
            note: "Seeded observation B — contradicts observation A"
          },
          confidence: 0.8,
          provenance: %{
            origin: :epistemic_seed,
            actor: :epistemic_seeder,
            note: "Battery B — noise reading"
          }
        }
      },
      %{
        name: :seed_stale,
        id: "seed_stale_#{stamp}",
        spec: %{
          id: "seed_stale_#{stamp}",
          type: :fact,
          subtype: :observation,
          domain: domain,
          attributes: %{
            property: "temperature_baseline",
            value: "legacy",
            evidence_chain: ["stale_source"],
            source_epoch: 2024,
            note: "Seeded stale theory — outdated baseline"
          },
          confidence: 0.6,
          provenance: %{
            origin: :epistemic_seed,
            actor: :epistemic_seeder,
            note: "Battery C — stale evidence chain"
          }
        }
      },
      %{
        name: :seed_lowconf,
        id: "seed_lowconf_#{stamp}",
        spec: %{
          id: "seed_lowconf_#{stamp}",
          type: :fact,
          subtype: :observation,
          domain: domain,
          attributes: %{
            property: "novel_signal",
            value: "unverified",
            note: "Seeded low-confidence measurement"
          },
          confidence: 0.3,
          provenance: %{
            origin: :epistemic_seed,
            actor: :epistemic_seeder,
            note: "Battery D — low confidence measurement"
          }
        }
      }
    ]
  end

  defp build_report(domain, specs, created) do
    created_ids = MapSet.new(Enum.map(created, fn {_name, id, _r} -> id end))
    created_specs = Enum.filter(specs, fn s -> MapSet.member?(created_ids, s.id) end)
    count = length(created_specs)

    if count == 0 do
      %{
        contradiction_rate: 0.0,
        evidence_quality: 1.0,
        stale_theory_rate: 0.0,
        provenance_completeness: 1.0,
        experiment_recommendations: []
      }
    else
      names = MapSet.new(Enum.map(created_specs, & &1.name))
      confidences = Enum.map(created_specs, & &1.spec.confidence)
      mean_confidence = Enum.sum(confidences) / count

      %{
        contradiction_rate:
          if(MapSet.member?(names, :seed_obs_a) and MapSet.member?(names, :seed_obs_b),
            do: 1.0 / count,
            else: 0.0
          ),
        evidence_quality: mean_confidence,
        stale_theory_rate: if(MapSet.member?(names, :seed_stale), do: 1.0 / count, else: 0.0),
        provenance_completeness: 1.0,
        experiment_recommendations: [
          %{
            domain: domain,
            reason: "Seeded contradiction between observation A and B",
            type: :resolve_contradictions,
            severity: :medium,
            estimated_impact: 0.6
          }
        ]
      }
    end
  end

  defp safe_gaps(report) do
    report
    |> GapAnalyzer.analyze()
    |> GapAnalyzer.rank()
  rescue
    e ->
      Logger.warning("[EpistemicSeeder] GapAnalyzer failed: #{Exception.message(e)}")
      []
  end

  defp safe_contradictions(domain, created) do
    ids = Enum.map(created, fn {_name, id, _r} -> id end)

    if length(created) >= 2 do
      %{
        contradictions: [
          %{
            type: :direct,
            domain: domain,
            entity_ids: ids,
            description: "Seeded contradiction between observations"
          }
        ],
        contradictions_classified: false,
        analysis_complete: false
      }
      |> ContradictionAnalyzer.analyze()
      |> Map.get(:contradictions, [])
    else
      []
    end
  rescue
    e ->
      Logger.warning("[EpistemicSeeder] ContradictionAnalyzer failed: #{Exception.message(e)}")
      []
  end

  defp persist_manifest(manifest) do
    manifest_file = manifest_file()
    Path.dirname(manifest_file) |> File.mkdir_p!()
    File.write!(manifest_file, Jason.encode!(manifest, pretty: true))
  end

  # Context-resolved at runtime so test/soak runs never overwrite the
  # production manifest (see Tiannara.Storage.Paths).
  defp manifest_file, do: Paths.path("epistemic_seed/latest_manifest.json")
end
