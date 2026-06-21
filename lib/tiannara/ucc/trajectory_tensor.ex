defmodule Tiannara.UCC.TrajectoryTensor do
  @moduledoc """
  Coordinator for Phase 11.7 (Trajectory Tensor Discovery).
  Samples coordinates from 5 different trajectory families and queries the Python micro-physics engine over NATS.
  Calculates orbital fitness (Generator Sustainability Index) and outputs the results.
  """
  use GenServer
  require Logger

  @output_path "data/archive/rea_generativity_trajectory_tensor.json"

  # Base coordinates for the 5 trajectory families in 4D retention space: T, H, C, I
  @families %{
    "Settler" => {0.80, 0.80, 0.20, 0.20},
    "Explorer" => {0.50, 0.90, 0.30, 0.70},
    "Trader" => {0.90, 0.20, 0.80, 0.80},
    "Survivor" => {0.95, 0.90, 0.10, 0.10},
    "Phoenix" => {0.30, 0.90, 0.90, 0.90}
  }

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc """
  Runs the 500-iteration trajectory tensor discovery process.
  """
  def run_discovery(pid) do
    GenServer.call(pid, :run_discovery, :infinity)
  end

  @impl true
  def init(_opts) do
    {:ok, %{}}
  end

  @impl true
  def handle_call(:run_discovery, _from, state) do
    Logger.info("Starting Phase 11.7 Trajectory Tensor Discovery Coordinator...")

    case Gnat.start_link(%{host: "127.0.0.1", port: 4222}) do
      {:ok, gnat} ->
        Logger.info("Connected to NATS on 127.0.0.1:4222.")

        # Generate the 500 coordinate requests (100 per family)
        requests = generate_samples()

        Logger.info("Evaluating 500 samples over NATS...")
        results =
          requests
          |> Stream.with_index()
          |> Enum.map(fn {req, idx} ->
            if rem(idx, 50) == 0 do
              Logger.info("Evaluated #{idx}/500 samples...")
            end

            query_micro_physics(gnat, req)
          end)

        # Stop private NATS connection
        GenServer.stop(gnat)

        # Filter out errors and keep valid results
        valid_results = Enum.filter(results, &Map.has_key?(&1, :gsi))

        if length(valid_results) > 0 do
          save_results(valid_results)
          rankings = analyze_families(valid_results)
          {:reply, {:ok, %{results_count: length(valid_results), rankings: rankings}}, state}
        else
          Logger.error("Trajectory Tensor Discovery failed: 0 valid results returned from micro-physics engine.")
          {:reply, {:error, :no_valid_results}, state}
        end

      {:error, reason} ->
        Logger.error("Failed to connect to NATS server: #{inspect(reason)}")
        {:reply, {:error, :nats_connection_failed}, state}
    end
  end

  defp generate_samples do
    # 5 families * 100 samples = 500 samples total
    Enum.flat_map(@families, fn {family_name, {t, h, c, i}} ->
      Enum.map(1..100, fn _ ->
        %{
          "T" => clip(t + random_perturbation()),
          "H" => clip(h + random_perturbation()),
          "C" => clip(c + random_perturbation()),
          "I" => clip(i + random_perturbation()),
          "family" => family_name
        }
      end)
    end)
  end

  defp random_perturbation do
    # [-0.15, +0.15]
    :rand.uniform() * 0.30 - 0.15
  end

  defp clip(val) do
    val |> max(0.0) |> min(1.0) |> Float.round(4)
  end

  defp query_micro_physics(gnat, req) do
    payload = Jason.encode!(req)

    case Gnat.request(gnat, "tiannara.ucc.trajectory_tensor.request", payload, receive_timeout: 120_000) do
      {:ok, %{body: body}} ->
        case Jason.decode(body) do
          {:ok, data} ->
            Map.new(data, fn {k, v} -> {String.to_atom(k), v} end)

          _ ->
            %{error: "Invalid JSON response from python", req: req}
        end

      {:error, reason} ->
        %{error: "NATS request failed: #{inspect(reason)}", req: req}
    end
  end

  defp save_results(results) do
    File.mkdir_p!(Path.dirname(@output_path))

    # Sort results by GSI descending
    sorted = Enum.sort_by(results, &Map.get(&1, :gsi, 0.0), :desc)

    report = %{
      "metadata" => %{
        "timestamp" => DateTime.utc_now() |> DateTime.to_iso8601(),
        "total_samples" => length(results),
        "hypothesis" => "Generativity is not a state variable. Generativity is a regenerative orbit."
      },
      "results" => sorted
    }

    File.write!(@output_path, Jason.encode_to_iodata!(report, pretty: true))
    Logger.info("Saved Trajectory Tensor Discovery report to #{@output_path}")
  end

  defp analyze_families(results) do
    grouped = Enum.group_by(results, fn res -> Map.get(res, :family) end)

    rankings =
      grouped
      |> Enum.map(fn {family, list} ->
        gsis = Enum.map(list, &Map.get(&1, :gsi, 0.0))
        avg_gsi = Enum.sum(gsis) / length(list)
        max_gsi = Enum.max(gsis)

        %{
          family: family,
          average_gsi: Float.round(avg_gsi, 4),
          max_gsi: Float.round(max_gsi, 4),
          count: length(list)
        }
      end)
      |> Enum.sort_by(& &1.max_gsi, :desc)

    Logger.info("Trajectory Family Rankings:")
    Enum.each(rankings, fn r ->
      Logger.info("  Family: #{r.family} | Max GSI: #{r.max_gsi} | Avg GSI: #{r.average_gsi}")
    end)

    rankings
  end
end
