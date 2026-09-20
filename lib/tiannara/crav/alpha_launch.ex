defmodule Tiannara.CRAV.AlphaLaunch do
  @moduledoc """
  Manages the Alpha Discovery Challenge launch protocol.

  Executes a pre-flight checklist and, only after a valid human authorization,
  records an auditable launch activation record. This module does not mint
  certification certificates.
  """

  use GenServer

  require Logger

  @telemetry_event [:tiannara, :alpha, :launched]
  @telemetry_pre_flight [:tiannara, :alpha, :pre_flight]

  @min_soak_hours 24.0
  @min_observatory_coverage 50.0
  @min_compliance_score 0.80

  defstruct [:state, :launch_record, :launched_at, :pre_flight_result]

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @spec pre_flight() :: {:ok, map()} | {:error, term()}
  def pre_flight do
    try do
      craf_result = check_crav_readiness()
      census_result = check_runtime_census()
      chain_result = check_discovery_chain()
      observatory_result = check_observatory_coverage()
      soak_result = check_soak_test()
      compliance_result = check_compliance()

      checklist = %{
        crav_ready: craf_result,
        runtime_census: census_result,
        discovery_chain: chain_result,
        observatory_coverage: observatory_result,
        soak_test: soak_result,
        compliance: compliance_result
      }

      all_pass = Enum.all?(Map.values(checklist), & &1.pass)

      critical_blockers =
        checklist
        |> Enum.reject(fn {_k, v} -> v.pass end)
        |> Enum.map(fn {k, v} -> %{check: k, reason: v.reason} end)

      result =
        Map.merge(checklist, %{
          overall_pass: all_pass,
          critical_blockers: critical_blockers
        })

      measurements = %{
        checks_passed: Enum.count(Map.values(checklist), & &1.pass),
        checks_total: map_size(checklist),
        overall_pass: all_pass
      }

      metadata = %{timestamp: DateTime.utc_now()}
      :telemetry.execute(@telemetry_pre_flight, measurements, metadata)

      if gen_server_running?() do
        GenServer.cast(__MODULE__, {:store_pre_flight, result})
      end

      {:ok, result}
    rescue
      err -> {:error, {:pre_flight_failed, err}}
    end
  end

  @spec launch() :: {:error, :authorization_required | term()}
  def launch, do: {:error, :authorization_required}

  @spec launch(term(), Tiannara.Omega.HumanDelivery.Authorization.t(), Tiannara.Omega.HumanDelivery.AuthenticatedHumanIdentity.t(), binary()) ::
          {:ok, map()} | {:error, term()}
  def launch(:crav_alpha_launch, grant, identity, registry_path) when is_binary(registry_path) do
    action_id = :crav_alpha_launch


    case pre_flight() do
      {:ok, checklist} ->
        cond do
          not checklist.overall_pass and has_critical_blockers?(checklist) ->
            {:error, {:launch_blocked, checklist.critical_blockers}}

          true ->
            case Tiannara.Omega.ConsequentialActionGate.consume(
                   action_id,
                   grant,
                   identity,
                   registry_path
                 ) do
              {:ok, receipt} -> execute_launch(checklist, receipt)
              {:error, reason} -> {:error, {:authorization_required, reason}}
            end
        end

      {:error, _} = err ->
        err
    end
  end

  @spec status() :: {:ok, atom()} | {:error, term()}
  def status do
    if gen_server_running?() do
      {:ok, GenServer.call(__MODULE__, :status)}
    else
      {:ok, :pre_launch}
    end
  end

  @spec certificate() :: {:ok, map() | nil} | {:error, term()}
  def launch_record do
    if gen_server_running?() do
      {:ok, GenServer.call(__MODULE__, :launch_record)}
    else
      {:ok, nil}
    end
  end

  @spec abort() :: {:ok, :aborted} | {:error, term()}
  def abort do
    if gen_server_running?() do
      GenServer.cast(__MODULE__, :abort)
      Logger.info("[AlphaLaunch] Launch aborted, returned to pre-launch state")
      {:ok, :aborted}
    else
      {:ok, :aborted}
    end
  end

  @impl true
  def init(_opts) do
    {:ok,
     %__MODULE__{state: :pre_launch, launch_record: nil, launched_at: nil, pre_flight_result: nil}}
  end

  @impl true
  def handle_call(:status, _from, state) do
    {:reply, state.state, state}
  end

  @impl true
  def handle_call(:launch_record, _from, state) do
    {:reply, state.certificate, state}
  end

  @impl true
  def handle_cast({:store_pre_flight, result}, state) do
    {:noreply, %{state | pre_flight_result: result}}
  end

  @impl true
  def handle_cast(:abort, _state) do
    {:noreply,
     %__MODULE__{state: :pre_launch, certificate: nil, launched_at: nil, pre_flight_result: nil}}
  end

  @impl true
  def handle_cast({:transition, new_state, launch_record}, state) do
    {:noreply, %{state | state: new_state, launch_record: launch_record, launched_at: DateTime.utc_now()}}
  end

  defp execute_launch(checklist, authorization_receipt) do
    if gen_server_running?() do
      GenServer.cast(__MODULE__, {:transition, :launching, nil})
    end

    launch_record = generate_launch_record(checklist, authorization_receipt)

    if gen_server_running?() do
      GenServer.cast(__MODULE__, {:transition, :active, launch_record})
    end

    measurements = %{
      observatory_coverage: checklist.observatory_coverage.value,
      soak_hours: checklist.soak_test.value,
      compliance_score: checklist.compliance.value
    }

    metadata = %{
      action_id: launch_record.action_id,
      authorization_id: launch_record.authorization_id,
      recommendation: launch_record.recommendation,
      timestamp: launch_record.activated_at
    }

    :telemetry.execute(@telemetry_event, measurements, metadata)

    Logger.info("[AlphaLaunch] Launch complete — action=#{launch_record.action_id}")

    {:ok, %{launch: launch_record, state: :active}}
  end

  defp has_critical_blockers?(checklist) do
    Enum.any?(checklist.critical_blockers, fn blocker ->
      blocker.check in [:crav_ready, :discovery_chain]
    end)
  end

  defp check_crav_readiness do
    result =
      if Code.ensure_loaded?(Tiannara.CRAV.LaunchReadiness) do
        case Tiannara.CRAV.LaunchReadiness.score() do
          {:ok, score} ->
            recommendation = score.recommendation
            overall = score.overall_alpha_readiness

            pass = recommendation in [:ready, :conditional]

            reason =
              if not pass, do: "CRAV readiness #{recommendation}, overall=#{overall}%", else: nil

            %{pass: pass, value: overall, recommendation: recommendation, reason: reason}

          {:error, err} ->
            %{pass: false, value: 0.0, recommendation: :blocked, reason: inspect(err)}
        end
      else
        %{
          pass: false,
          value: 0.0,
          recommendation: :blocked,
          reason: "LaunchReadiness not available"
        }
      end

    result
  end

  defp check_runtime_census do
    if Code.ensure_loaded?(Tiannara.CRAV.RuntimeCensus) do
      case Tiannara.CRAV.RuntimeCensus.census() do
        {:ok, entries} ->
          total = length(entries)
          alive = Enum.count(entries, &(&1.status == :alive))
          pass = total > 0 and alive > 0
          reason = if not pass, do: "No subsystems alive (total=#{total})", else: nil
          %{pass: pass, total: total, alive: alive, reason: reason}

        {:error, err} ->
          %{pass: false, total: 0, alive: 0, reason: inspect(err)}
      end
    else
      %{pass: false, total: 0, alive: 0, reason: "RuntimeCensus not available"}
    end
  end

  defp check_discovery_chain do
    if Code.ensure_loaded?(Tiannara.CRAV.DiscoveryChain) do
      case Tiannara.CRAV.DiscoveryChain.verify() do
        {:ok, results} ->
          total = length(results)
          reachable = Enum.count(results, & &1.reachable)
          pass = reachable == total
          reason = if not pass, do: "#{total - reachable} stages unreachable", else: nil
          %{pass: pass, total: total, reachable: reachable, reason: reason}

        {:error, err} ->
          %{pass: false, total: 12, reachable: 0, reason: inspect(err)}
      end
    else
      %{pass: false, total: 12, reachable: 0, reason: "DiscoveryChain not available"}
    end
  end

  defp check_observatory_coverage do
    if Code.ensure_loaded?(Tiannara.CRAV.ObservatoryCoverage) do
      case Tiannara.CRAV.ObservatoryCoverage.overall_coverage() do
        {:ok, coverage} ->
          pct = coverage * 100
          pass = pct >= @min_observatory_coverage

          reason =
            if not pass,
              do: "Coverage #{Float.round(pct, 1)}% below #{@min_observatory_coverage}%",
              else: nil

          %{
            pass: pass,
            value: Float.round(pct, 1),
            threshold: @min_observatory_coverage,
            reason: reason
          }

        {:error, err} ->
          %{pass: false, value: 0.0, threshold: @min_observatory_coverage, reason: inspect(err)}
      end
    else
      %{
        pass: false,
        value: 0.0,
        threshold: @min_observatory_coverage,
        reason: "ObservatoryCoverage not available"
      }
    end
  end

  defp check_soak_test do
    hours = determine_soak_hours()
    pass = hours >= @min_soak_hours

    reason =
      if not pass,
        do: "Soak test #{Float.round(hours, 1)}h below #{@min_soak_hours}h minimum",
        else: nil

    %{pass: pass, value: Float.round(hours, 1), threshold: @min_soak_hours, reason: reason}
  end

  defp determine_soak_hours do
    cond do
      Code.ensure_loaded?(Tiannara.CRAV.SoakTest) and Process.whereis(Tiannara.CRAV.SoakTest) ->
        try do
          status = Tiannara.CRAV.SoakTest.status()
          Map.get(status, :elapsed_hours, 0.0)
        rescue
          _ -> 0.0
        end

      File.exists?(Tiannara.Storage.Paths.path("soak_final_report.json")) ->
        try do
          {:ok, body} = File.read(Tiannara.Storage.Paths.path("soak_final_report.json"))
          {:ok, decoded} = Jason.decode(body)
          Map.get(decoded, "elapsed_hours", 0.0)
        rescue
          _ -> 0.0
        end

      true ->
        0.0
    end
  end

  defp check_compliance do
    if Code.ensure_loaded?(Tiannara.CRAV.ComplianceAudit) do
      case Tiannara.CRAV.ComplianceAudit.overall_compliance() do
        {:ok, compliance} ->
          pct = compliance * 100
          pass = pct >= @min_compliance_score * 100

          reason =
            if not pass,
              do: "Compliance #{Float.round(pct, 1)}% below #{@min_compliance_score * 100}%",
              else: nil

          %{
            pass: pass,
            value: Float.round(pct, 1),
            threshold: @min_compliance_score * 100,
            reason: reason
          }

        {:error, err} ->
          %{pass: false, value: 0.0, threshold: @min_compliance_score * 100, reason: inspect(err)}
      end
    else
      %{
        pass: false,
        value: 0.0,
        threshold: @min_compliance_score * 100,
        reason: "ComplianceAudit not available"
      }
    end
  end

  defp generate_launch_record(checklist, authorization_receipt) do
    now = DateTime.utc_now()

    conditions = %{
      runtime_ready: checklist.runtime_census.pass,
      discovery_chain_complete: checklist.discovery_chain.pass,
      observatory_coverage: checklist.observatory_coverage.value,
      soak_test_hours: checklist.soak_test.value,
      compliance_score: checklist.compliance.value
    }

    sac = build_sac()
    recommendation = compute_launch_recommendation(checklist)

    hash_input =
      Jason.encode!(%{
        action_id: authorization_receipt.action_id,
        authorization_id: authorization_receipt.authorization_id,
        activated_at: DateTime.to_iso8601(now),
        conditions: conditions,
        recommendation: Atom.to_string(recommendation),
        self_assessment_state: sac.state,
        self_assessment_instrumented: "#{sac.instrumented_stages}/#{sac.total_stages}"
      })

    hash = :crypto.hash(:sha256, hash_input) |> Base.encode16(case: :lower)

    %{
      action_id: authorization_receipt.action_id,
      authorization_id: authorization_receipt.authorization_id,
      activated_at: now,
      activation_hash: hash,
      launch_conditions: conditions,
      recommendation: recommendation,
      self_assessment: sac,
      authorized_by: authorization_receipt.human_id,
      version: "2.0.0"
    }
  end

  defp build_sac do
    snapshot =
      if Process.whereis(Tiannara.Discovery.PipelineTelemetry) != nil do
        Tiannara.Discovery.PipelineTelemetry.snapshot()
      else
        %{stages: %{}}
      end

    manifest = Tiannara.Discovery.EpistemicSeeder.last_manifest()
    stages = Map.get(snapshot, :stages, %{})
    total = map_size(stages)

    uninstrumented =
      Enum.filter(stages, fn {_s, st} -> st.status == :uninstrumented end)
      |> Enum.map(fn {s, _} -> s end)

    instrumented = total - length(uninstrumented)

    state =
      cond do
        uninstrumented != [] -> :unmeasurable
        Enum.any?(stages, fn {_s, st} -> st.status in [:growing, :regressed] end) -> :active
        total > 0 -> :quiet
        true -> :unmeasurable
      end

    %{
      state: state,
      instrumented_stages: instrumented,
      total_stages: total,
      uninstrumented: uninstrumented,
      first_stall: Map.get(snapshot, :first_stall),
      seeded_input_manifest: manifest,
      rule:
        "SAC is a hard pass criterion only when all pipeline stages are instrumented AND the seeded-input manifest exists. A quiet/unmeasurable SAC on an unseeded run is expected, not a failure."
    }
  end


  defp compute_launch_recommendation(checklist) do
    pass_count =
      checklist
      |> Map.take([
        :crav_ready,
        :runtime_census,
        :discovery_chain,
        :observatory_coverage,
        :soak_test,
        :compliance
      ])
      |> Map.values()
      |> Enum.count(& &1.pass)

    total = 6

    cond do
      pass_count == total -> :ready
      pass_count < 3 -> :blocked
      true -> :conditional
    end
  end

  defp gen_server_running? do
    Process.whereis(__MODULE__) != nil and Process.alive?(Process.whereis(__MODULE__))
  rescue
    _ -> false
  end
end
