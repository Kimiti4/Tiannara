defmodule Tiannara.Council.EmergencyState do
  @moduledoc """
  Authoritative Council emergency snapshot with durable persistence.
  """

  @key {Tiannara.Council, :emergency_snapshot}
  # @file "emergency_state.bin"

  @default %{
    active: false,
    invoked_by: nil,
    reason: nil,
    invoked_at: nil,
    epoch: 0
  }

  @emergency_allowed_decisions [:emergency_halt, :circuit_breaker]

  def publish(%{active: active} = emergency) when is_boolean(active) do
    snapshot = Map.merge(@default, emergency)
    :persistent_term.put(@key, snapshot)
    persist(snapshot)
    :ok
  end

  def load do
    p = safe_path()

    case File.read(p) do
      {:ok, binary} ->
        try do
          decoded = :erlang.binary_to_term(binary, [:safe])

          if is_map(decoded) and is_boolean(Map.get(decoded, :active, false)) do
            :persistent_term.put(@key, Map.merge(@default, decoded))
          end
        rescue
          _ -> :ok
        end

      {:error, _} ->
        :ok
    end

    :ok
  end

  def snapshot, do: :persistent_term.get(@key, @default)

  def active?, do: snapshot().active == true

  def epoch, do: Map.get(snapshot(), :epoch, 0)

  def emergency_allowed_decisions, do: @emergency_allowed_decisions

  def decision_allowed?(decision_type), do: decision_type in @emergency_allowed_decisions

  def effect_allowed?(_operation), do: false

  def reset_test_state do
    if Application.get_env(:tiannara, :allow_test_receipt_signing, false) == true do
      :persistent_term.put(@key, @default)
      _ = File.rm(safe_path())
      :ok
    else
      {:error, :not_allowed}
    end
  end

  defp safe_path do
    base =
      case Application.get_env(:tiannara, :dets_base_path) do
        nil ->
          "./data/dets"

        v when is_binary(v) ->
          v

        v when is_list(v) ->
          List.to_string(v)

        v ->
          to_string(v)
      end

    Path.join(base, "emergency_state.bin")
  end

  defp persist(snapshot) do
    try do
      p = safe_path()
      File.mkdir_p!(Path.dirname(p))
      File.write!(p, :erlang.term_to_binary(snapshot, [:compressed]))
    rescue
      _ -> :ok
    end
  end


end
