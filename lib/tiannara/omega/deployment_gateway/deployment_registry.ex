defmodule Tiannara.Omega.DeploymentGateway.DeploymentRegistry do
  @moduledoc """
  Tracks deployed authorization grants for idempotency. After a successful
  deployment, the grant's authorization_id is recorded. Replaying the same
  grant is rejected, preventing duplicate deployment.

  Constitutional basis: Safety and Reliability, "Maintain audit trails",
  "Support reproducibility."
  """

  def record_deployment(authorization_id, effect_identity, deployment_id, path) do
    File.mkdir_p!(Path.dirname(path))
    entry = {authorization_id, effect_identity, deployment_id, System.system_time(:millisecond)}
    serialized = :erlang.term_to_binary(entry)
    File.write(path, [<<byte_size(serialized)::32>>, serialized], [:append])
  end

  def deployment_status(authorization_id, effect_identity, path) do
    case File.read(path) do
      {:ok, content} ->
        content
        |> decode_records()
        |> status_for(authorization_id, effect_identity)

      _ ->
        :not_deployed
    end
  end

  defp status_for(records, authorization_id, effect_identity) do
    case Enum.find(records, fn
           {^authorization_id, ^effect_identity, _deployment_id, _timestamp} -> true
           {^authorization_id, _legacy_deployment_id, _legacy_timestamp} -> true
           _ -> false
         end) do
      {^authorization_id, ^effect_identity, _deployment_id, _timestamp} ->
        :same_effect

      {^authorization_id, _legacy_deployment_id, _legacy_timestamp} ->
        :different_effect

      nil ->
        if Enum.any?(records, fn
             {^authorization_id, _other_effect, _deployment_id, _timestamp} -> true
             _ -> false
           end),
           do: :different_effect,
           else: :not_deployed
    end
  end

  defp decode_records(<<>>), do: []

  defp decode_records(<<size::32, term::binary-size(size), rest::binary>>) do
    [:erlang.binary_to_term(term) | decode_records(rest)]
  end

  defp decode_records(_truncated), do: []
end
