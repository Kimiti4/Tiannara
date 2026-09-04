defmodule Tiannara.Integration.RunContext do
  @moduledoc """
  Context containing all loaded artifacts for a soak run.
  """

  defstruct [
    :funnel,
    :observatory,
    :knowledge,
    :results_summary,
    :checkpoint_integrity,
    :availability,
    :gate_verdict,
    :recovery_certificate,
    :constitutional_invariants,
    validated_seconds: 0
  ]

  def load(paths) do
    funnel = load_funnel(paths.funnel_events)
    observatory = load_observatory(paths.telemetry)
    knowledge = load_knowledge(paths.knowledge_dir)
    results_summary = load_results_summary(paths.checkpoint_dir)
    checkpoint_integrity = load_checkpoint_integrity(paths.checkpoint_dir)
    availability = load_availability(paths.telemetry)
    gate_verdict = load_gate_verdict(paths.recovery_attestation)
    recovery_certificate = load_recovery_certificate(paths.recovery_certificate)
    constitutional_invariants =
      load_constitutional_invariants(paths.constitutional_invariants) || derive_constitutional(funnel)
    validated_seconds = load_validated_seconds(paths.checkpoint_dir)

    %__MODULE__{
      funnel: funnel,
      observatory: observatory,
      knowledge: knowledge,
      results_summary: results_summary,
      checkpoint_integrity: checkpoint_integrity,
      availability: availability,
      gate_verdict: gate_verdict,
      recovery_certificate: recovery_certificate,
      constitutional_invariants: constitutional_invariants,
      validated_seconds: validated_seconds
    }
  end

  defp load_funnel(nil), do: nil
  defp load_funnel(path) do
    case File.read(path) do
      {:ok, bin} -> :erlang.binary_to_term(bin)
      _ -> nil
    end
  end

  defp load_observatory(nil), do: nil
  defp load_observatory(path) do
    case File.read(path) do
      {:ok, bin} -> :erlang.binary_to_term(bin)
      _ -> nil
    end
  end

  defp load_knowledge(nil), do: nil
  defp load_knowledge(path) do
    case File.read(path) do
      {:ok, bin} -> :erlang.binary_to_term(bin)
      _ -> nil
    end
  end

  defp load_results_summary(nil), do: %{}

  defp load_results_summary(dir) do
    case Tiannara.Soak.CheckpointStore.IsolatedFileStore.open(dir, "audit") do
      {:ok, store} ->
        case store.__struct__.latest_valid(store) do
          {:ok, cp} -> %{latest_elapsed_seconds: cp.elapsed_seconds}
          :none -> %{}
        end

      _ ->
        %{}
    end
  end

  defp load_checkpoint_integrity(nil), do: %{latest_valid?: false, corrupt: 0}

  defp load_checkpoint_integrity(dir) do
    case Tiannara.Soak.CheckpointStore.IsolatedFileStore.open(dir, "audit") do
      {:ok, store} ->
        checkpoint_files =
          dir
          |> File.ls!()
          |> Enum.filter(&String.starts_with?(&1, "checkpoint-"))

        valid_count =
          checkpoint_files
          |> Enum.count(fn name ->
            case File.read(Path.join(dir, name)) do
              {:ok, bin} -> match?({:ok, _}, Tiannara.Soak.Checkpoint.deserialize(bin))
              _ -> false
            end
          end)

        %{
          latest_valid?: match?({:ok, _}, store.__struct__.latest_valid(store)),
          corrupt: length(checkpoint_files) - valid_count
        }

      _ ->
        %{latest_valid?: false, corrupt: 0}
    end
  end

  defp load_availability(nil), do: 1.0
  defp load_availability(path) do
    # Placeholder implementation
    1.0
  end

  defp load_gate_verdict(nil), do: :gate_closed
  defp load_gate_verdict(path) do
    case File.read(path) do
      {:ok, bin} -> :erlang.binary_to_term(bin)
      _ -> :gate_closed
    end
  end

  defp load_recovery_certificate(nil), do: nil

  defp load_recovery_certificate(path) do
    case Tiannara.Soak.RecoveryCertificate.load(path) do
      {:ok, cert} -> cert
      _ -> nil
    end
  end

  defp load_constitutional_invariants(nil), do: nil

  defp load_constitutional_invariants(path) do
    case File.read(path) do
      {:ok, bin} -> :erlang.binary_to_term(bin)
      _ -> nil
    end
  end

  @doc """
  Derive constitutional invariant status from the funnel event log when no
  explicit artifact was persisted: every non-terminal stage must be promoted
  to its successor, and no stage may be created without an incoming parent
  (except the root observation).
  """
  def derive_constitutional(nil), do: nil

  def derive_constitutional(events) when is_list(events) do
    created =
      for {:created, stage, _id, parents} <- events do
        {stage, parents}
      end

    promoted =
      for {:disposition, stage, _id, :promoted, _target} <- events do
        stage
      end

    root = case created do
      [{root_stage, _} | _] -> root_stage
      _ -> nil
    end
    terminal = if created == [], do: nil, else: List.last(created) |> elem(0)

    failing =
      []
      |> then(fn f ->
        case Enum.find(created, fn {s, parents} -> s != root and parents == [] end) do
          nil -> f
          {s, _} -> f ++ [{:root_without_parent, s}]
        end
      end)
      |> then(fn f ->
        case Enum.find(created, fn {s, _} -> s != terminal and s not in promoted end) do
          nil -> f
          {s, _} -> f ++ [{:not_promoted, s}]
        end
      end)

    %{all_passed: failing == [], failing_scenarios: failing}
  end

  defp load_validated_seconds(nil), do: 0

  defp load_validated_seconds(dir) do
    case Tiannara.Soak.CheckpointStore.IsolatedFileStore.open(dir, "audit") do
      {:ok, store} ->
        case store.__struct__.latest_valid(store) do
          {:ok, cp} -> cp.elapsed_seconds
          :none -> 0
        end

      _ ->
        0
    end
  end
end