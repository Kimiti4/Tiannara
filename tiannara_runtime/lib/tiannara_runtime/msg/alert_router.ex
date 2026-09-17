defmodule Tiannara.AlertRouter do
  @moduledoc """
  ⚡ ALERT ROUTING SYSTEM (NEURAL FIRE MODEL)
  
  Implements a biological-like event propagation system where alerts behave
  like firing neurons with synaptic weights, decay, and amplification.
  """

  require Logger

  @doc """
  Routes a signal based on severity using the neural path.
  """
  def route(signal) do
    # Support maps with string or atom keys
    signal_map = ensure_atom_keys(signal)
    severity = Map.get(signal_map, :severity, :medium)

    case severity do
      :critical -> broadcast_neuron(signal_map, :fast_path)
      :high     -> broadcast_neuron(signal_map, :priority_path)
      :medium   -> broadcast_neuron(signal_map, :normal_path)
      :low      -> broadcast_neuron(signal_map, :background)
      _         -> broadcast_neuron(signal_map, :normal_path)
    end
  end

  @doc """
  Amplify logic based on collapse probability.
  """
  def amplify(signal) do
    collapse_prob = Map.get(signal, :collapse_probability, 0.0)

    signal
    |> increase_weight(collapse_prob > 0.7)
    |> tag(:hot_zone)
    |> propagate_to_neighbors()
  end

  defp increase_weight(signal, true) do
    Map.update(signal, :weight, 1.275, &(&1 * 1.5))
  end
  defp increase_weight(signal, false), do: signal

  defp tag(signal, tag_value) do
    Map.update(signal, :tags, [tag_value], fn tags -> 
      if tag_value in tags, do: tags, else: [tag_value | tags]
    end)
  end

  defp propagate_to_neighbors(signal) do
    # Propagation decay equation:
    # signal_strength = base_signal × weight × context_multiplier × decay_factor
    context_multiplier = get_context_multiplier(signal)
    decay_factor = 0.88 # 1.0 - 0.12 decay
    base_signal = Map.get(signal, :strength, 1.0)
    weight = Map.get(signal, :weight, 0.85)

    signal_strength = base_signal * weight * context_multiplier * decay_factor

    threshold = 0.7
    if signal_strength > threshold do
      broadcast_to_dashboard(signal, signal_strength)
      Map.put(signal, :fired, true)
    else
      Map.put(signal, :fired, false)
    end
  end

  defp get_context_multiplier(signal) do
    collapse_prob = Map.get(signal, :collapse_probability, 0.0)
    entropy = Map.get(signal, :entropy, 0.5)
    issue = Map.get(signal, :detected_issue)
    state = Map.get(signal, :state)

    cond do
      collapse_prob > 0.7 -> 2.5 # exponential amplification
      issue == :monoculture_risk -> 1.8 # increase alert propagation
      entropy > 0.8 -> 1.5 # amplify CIS sensitivity
      state == :stable -> 0.5 # dampen signals
      true -> 1.0
    end
  end

  defp broadcast_neuron(signal, path) do
    # Broadcaster to neural path
    amplified = amplify(signal)
    
    # Broadcast to Phoenix PubSub topics
    Phoenix.PubSub.broadcast(TiannaraRuntime.PubSub, "cis:alerts", {:cis_alert, amplified})
    
    # Send viz event to dashboard stream
    Phoenix.PubSub.broadcast(TiannaraRuntime.PubSub, "visualization", {:viz_event, %{
      "timestamp" => System.system_time(:second),
      "layer" => "cis",
      "entity_type" => "alert",
      "entity_id" => to_string(Map.get(signal, :civilization_id, "unknown")),
      "metrics" => %{
        "entropy" => Map.get(signal, :entropy, 0.0),
        "collapse_probability" => Map.get(signal, :collapse_probability, 0.0),
        "strength" => Map.get(amplified, :strength, 1.0) * Map.get(amplified, :weight, 0.85)
      },
      "state" => to_string(Map.get(signal, :state, "unknown")),
      "visual_type" => "red_pulse"
    }})

    {:ok, path, amplified}
  end

  defp broadcast_to_dashboard(signal, strength) do
    Phoenix.PubSub.broadcast(TiannaraRuntime.PubSub, "global:collapse_risk", {:global_risk, %{
      collapse_probability: Map.get(signal, :collapse_probability, 0.0),
      strength: strength,
      source: Map.get(signal, :civilization_id)
    }})
  end

  # Helper to normalize keys
  defp ensure_atom_keys(map) when is_map(map) do
    Enum.reduce(map, %{}, fn {k, v}, acc ->
      atom_key = if is_binary(k), do: String.to_atom(k), else: k
      Map.put(acc, atom_key, v)
    end)
  end
end

defmodule TiannaraRuntime.MSG.AlertRouter do
  @moduledoc """
  Proxy alias wrapper for Tiannara.AlertRouter.
  """
  defdelegate route(signal), to: Tiannara.AlertRouter
  defdelegate amplify(signal), to: Tiannara.AlertRouter
end
