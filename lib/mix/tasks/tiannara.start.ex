defmodule Mix.Tasks.Tiannara.Start do
  use Mix.Task

  @shortdoc "One-click Tiannara startup with constitutional verification"

  @profiles %{
    "dev" => [:env, :infra, :runtime, :api, :frontend, :health],
    "research" => [:env, :infra, :runtime, :api, :health],
    "production" => [:env, :infra, :runtime, :api, :frontend, :health],
    "benchmark" => [:env, :infra, :runtime, :health],
    "safe-mode" => [:env, :runtime, :health],
    "distributed" => [:env, :infra, :runtime, :api, :frontend, :health]
  }

  @default_profile "dev"

  @cpl_module TiannaraRuntime.OS.Persistence.ConstitutionalPersistenceLayer
  @cpl_max_wait_ms 10_000
  @cpl_poll_ms 200

  @required_services [
    %{name: "PostgreSQL", port: 5432},
    %{name: "Redis", port: 6379},
    %{name: "NATS", port: 4222}
  ]

  @runtime_subsystems [:telemetry, :tiannara, :tiannara_runtime]

  def run(args) do
    {opts, _, _} =
      OptionParser.parse(args,
        switches: [profile: :string, skip_infra: :boolean, skip_frontend: :boolean, safe: :boolean],
        aliases: [p: :profile, s: :safe]
      )

    profile = determine_profile(opts)
    phases = Map.get(@profiles, profile, @profiles[@default_profile])

    print_banner(profile)

    results =
      phases
      |> Enum.map(fn phase ->
        result = safe_execute_phase(phase, opts)
        print_phase_result(phase, result)
        {phase, result}
      end)

    print_final_summary(results, profile)

    keep_alive()
  end

  defp safe_execute_phase(phase, opts) do
    try do
      execute_phase(phase, opts)
    rescue
      error -> %{status: :error, message: Exception.message(error)}
    catch
      kind, reason -> %{status: :error, message: "#{kind}: #{inspect(reason)}"}
    end
  end

  defp determine_profile(opts) do
    cond do
      opts[:safe] -> "safe-mode"
      opts[:profile] -> opts[:profile]
      true -> @default_profile
    end
  end

  defp execute_phase(:env, _opts), do: phase_env_validation()
  defp execute_phase(:infra, opts), do: phase_infrastructure(opts)
  defp execute_phase(:runtime, _opts), do: phase_runtime()
  defp execute_phase(:api, _opts), do: phase_api()
  defp execute_phase(:frontend, _opts), do: phase_frontend()
  defp execute_phase(:health, _opts), do: phase_health()

  defp phase_env_validation do
    checks = [
      {"Elixir", check_version("elixir", "--version", ~r/Elixir (\d+\.\d+\.\d+)/)},
      {"Erlang/OTP", check_erlang_version()},
      {"Mix", check_mix_available()},
      {"Node.js", check_version("node", "--version", ~r/v?(\d+\.\d+\.\d+)/)},
      {"PostgreSQL", check_port(5432)},
      {"Redis", check_port(6379)},
      {"NATS", check_port(4222)}
    ]

    failures = Enum.filter(checks, fn {_, result} -> result == :missing end)

    %{checks: checks, failures: failures, status: if(failures == [], do: :pass, else: :warn)}
  end

  defp phase_infrastructure(opts) do
    if opts[:skip_infra] do
      %{status: :skipped, message: "Skipped"}
    else
      results =
        @required_services
        |> Enum.map(fn service ->
          case check_port(service.port) do
            :ok -> {service.name, :running}
            :missing -> {service.name, :stopped}
          end
        end)

      stopped = Enum.filter(results, fn {_, s} -> s == :stopped end)
      %{status: if(stopped == [], do: :pass, else: :warn), services: results, stopped: stopped}
    end
  end

  defp phase_runtime do
    Mix.Task.run("app.start")

    results =
      @runtime_subsystems
      |> Enum.map(fn app ->
        case Application.ensure_all_started(app) do
          {:ok, _} -> {app, :started}
          {:error, reason} -> {app, {:failed, reason}}
        end
      end)

    cpl_status = wait_for_cpl(@cpl_max_wait_ms)
    failed = Enum.filter(results, fn {_, s} -> s != :started end)
    status = if(failed == [] and cpl_status == :alive, do: :pass, else: :warn)

    %{status: status, apps: results, cpl: cpl_status}
  end

  defp phase_api do
    case Application.ensure_all_started(:phoenix) do
      {:ok, _} ->
        endpoint = ensure_endpoint_started()
        %{status: :pass, endpoint: endpoint}

      {:error, reason} ->
        %{status: :warn, error: reason}
    end
  rescue
    error -> %{status: :warn, error: inspect(error)}
  end

  defp phase_frontend do
    observatory_path = Path.join([File.cwd!(), "tiannara_observatory", "apps", "observatory_ui"])

    if File.dir?(observatory_path) do
      coa_path = Path.join([observatory_path, "public", "coa", "index.html"])
      %{status: :pass, path: observatory_path, coa_available: File.exists?(coa_path)}
    else
      %{status: :warn, message: "Observatory UI not found"}
    end
  end

  defp phase_health do
    crav_result = run_crav()

    health_checks = [
      {"CPL", safe_process_alive?(@cpl_module)},
      {"BEAM", true},
      {"Telemetry", safe_module_alive?(Tiannara.Telemetry)},
      {"SubsystemRegistry", safe_module_alive?(Tiannara.PhaseOmega.SubsystemRegistry)},
      {"BootSequencer", safe_module_alive?(Tiannara.PhaseOmega.BootSequencer)},
      {"RuntimeVerifier", safe_module_alive?(Tiannara.PhaseOmega.RuntimeVerifier)}
    ]

    passed = Enum.count(health_checks, fn {_, alive} -> alive end)
    total = length(health_checks)

    %{
      status: if(passed == total, do: :pass, else: :warn),
      checks: health_checks,
      passed: passed,
      total: total,
      crav: crav_result
    }
  rescue
    error -> %{status: :error, checks: [], passed: 0, total: 6, crav: {:error, error}}
  end

  defp print_banner(profile) do
    shell = Mix.shell()
    shell.info("")
    shell.info("═══════════════════════════════════════════════════════")
    shell.info("  TIANNARA RUNTIME LAUNCHER")
    shell.info("  Constitutional Operations Architecture")
    shell.info("  Profile: #{String.upcase(profile)}")
    shell.info("═══════════════════════════════════════════════════════")
    shell.info("")
  end

  defp print_phase_result(:env, result) do
    shell = Mix.shell()
    shell.info("Phase 0: Environment Validation")
    Enum.each(result.checks, fn {name, status} ->
      icon = if status == :ok, do: "  ✓", else: "  ✗"
      shell.info("#{icon} #{name}")
    end)
    shell.info("")
  end

  defp print_phase_result(:infra, %{status: :skipped, message: msg}) do
    Mix.shell().info("Phase 1: Infrastructure — #{msg}")
    Mix.shell().info("")
  end

  defp print_phase_result(:infra, result) do
    shell = Mix.shell()
    shell.info("Phase 1: Infrastructure")
    Enum.each(result.services, fn {name, status} ->
      icon = if status == :running, do: "  ✓", else: "  ✗"
      shell.info("#{icon} #{name}")
    end)
    shell.info("")
  end

  defp print_phase_result(:runtime, result) do
    shell = Mix.shell()
    shell.info("Phase 2: Runtime")
    Enum.each(result.apps, fn {app, status} ->
      icon = if status == :started, do: "  ✓", else: "  ✗"
      shell.info("#{icon} #{app}")
    end)
    cpl_icon = if result.cpl == :alive, do: "  ✓", else: "  ✗"
    shell.info("#{cpl_icon} CPL (Constitutional Persistence Layer)")
    shell.info("")
  end

  defp print_phase_result(:api, result) do
    shell = Mix.shell()
    shell.info("Phase 3: API")
    if result.status == :pass do
      shell.info("  ✓ Phoenix")
      if result[:endpoint], do: shell.info("  ✓ Endpoint")
    else
      shell.info("  ✗ Phoenix (#{inspect(result[:error])})")
    end
    shell.info("")
  end

  defp print_phase_result(:frontend, result) do
    shell = Mix.shell()
    shell.info("Phase 4: Frontend")
    if result.status == :pass do
      shell.info("  ✓ Observatory UI")
      if result[:coa_available], do: shell.info("  ✓ COA Dashboard")
    else
      shell.info("  ~ #{result[:message]}")
    end
    shell.info("")
  end

  defp print_phase_result(:health, result) do
    shell = Mix.shell()
    shell.info("Phase 5: Health Verification")

    if result.status == :error do
      shell.info("  ✗ Health check failed: #{result[:message]}")
      shell.info("")
    else
      Enum.each(result.checks, fn {name, alive} ->
        icon = if alive, do: "  ✓", else: "  ✗"
        shell.info("#{icon} #{name}")
      end)
      shell.info("")
      shell.info("  #{result.passed}/#{result.total} checks passed")

      case result.crav do
        {:ok, report} ->
          readiness = Map.get(report, :launch_readiness, %{})
          overall = Map.get(readiness, :overall_alpha_readiness, 0.0)
          verdict = Map.get(report, :verdict, :unknown)
          shell.info("  CRAV Readiness: #{overall}% (#{verdict |> to_string() |> String.upcase()})")

        _ ->
          shell.info("  CRAV: unavailable")
      end

      shell.info("")
    end
  end

  defp print_final_summary(results, profile) do
    shell = Mix.shell()
    all_pass = Enum.all?(results, fn {_, %{status: s}} -> s in [:pass, :skipped] end)
    any_fail = Enum.any?(results, fn {_, %{status: s}} -> s == :fail end)

    verdict = cond do
      all_pass -> "READY"
      any_fail -> "DEGRADED"
      true -> "OPERATIONAL"
    end

    shell.info("═══════════════════════════════════════════════════════")
    shell.info("  Status: #{verdict}")
    shell.info("  Profile: #{String.upcase(profile)}")

    if all_pass or not any_fail do
      shell.info("")
      shell.info("  Dashboard: http://localhost:4000/coa/index.html")
      shell.info("  Boot:      http://localhost:4000/coa/boot.html")
      shell.info("  API:       http://localhost:4000/api/observatory/status")
    end

    shell.info("═══════════════════════════════════════════════════════")
    shell.info("")
    shell.info("  Tiannara is running. Press Ctrl+C to stop.")
    shell.info("")
  end

  defp keep_alive do
    receive do
    after
      86_400_000 -> :ok
    end
  end

  defp check_version(cmd, arg, pattern) do
    case System.cmd(cmd, [arg], stderr_to_stdout: true) do
      {output, 0} ->
        case Regex.run(pattern, output) do
          [_, _] -> :ok
          _ -> :missing
        end
      _ -> :missing
    end
  rescue
    _ -> :missing
  end

  defp check_erlang_version do
    :erlang.system_info(:otp_release)
    :ok
  rescue
    _ -> :missing
  end

  defp check_mix_available do
    if Code.ensure_loaded?(Mix), do: :ok, else: :missing
  end

  defp check_port(port) do
    case :gen_tcp.connect(~c"localhost", port, [], 1000) do
      {:ok, socket} -> :gen_tcp.close(socket); :ok
      {:error, _} -> :missing
    end
  rescue
    _ -> :missing
  end

  defp ensure_endpoint_started do
    cond do
      Code.ensure_loaded?(TiannaraWeb.Endpoint) ->
        case TiannaraWeb.Endpoint.start_link() do
          {:ok, pid} -> pid
          {:error, {:already_started, pid}} -> pid
          _ -> nil
        end

      Code.ensure_loaded?(TiannaraRuntimeWeb.Endpoint) ->
        case apply(TiannaraRuntimeWeb.Endpoint, :start_link, []) do
          {:ok, pid} -> pid
          {:error, {:already_started, pid}} -> pid
          _ -> nil
        end

      true -> nil
    end
  rescue
    _ -> nil
  end

  defp safe_process_alive?(module) do
    case Process.whereis(module) do
      nil -> false
      pid -> Process.alive?(pid)
    end
  rescue
    _ -> false
  end

  defp safe_module_alive?(module) do
    case Process.whereis(module) do
      nil -> false
      pid -> Process.alive?(pid)
    end
  rescue
    _ -> false
  end

  defp wait_for_cpl(time_remaining) when time_remaining <= 0 do
    if cpl_alive?(), do: :alive, else: :not_started
  end

  defp wait_for_cpl(time_remaining) do
    if cpl_alive?() do
      :alive
    else
      Process.sleep(@cpl_poll_ms)
      wait_for_cpl(time_remaining - @cpl_poll_ms)
    end
  end

  defp cpl_alive? do
    case Process.whereis(@cpl_module) do
      nil -> false
      pid -> Process.alive?(pid)
    end
  rescue
    _ -> false
  end

  defp run_crav do
    if Code.ensure_loaded?(Tiannara.CRAV) do
      Tiannara.CRAV.run()
    else
      {:error, :crav_not_available}
    end
  rescue
    error -> {:error, error}
  end
end
