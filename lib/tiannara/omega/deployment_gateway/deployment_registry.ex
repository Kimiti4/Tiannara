defmodule Tiannara.Omega.DeploymentGateway.DeploymentRegistry do
  @moduledoc """
  Tracks deployed authorization grants for idempotency. After a successful
  deployment, the grant's authorization_id is recorded. Replaying the same
  grant is rejected, preventing duplicate deployment.

  Constitutional basis: Safety and Reliability, "Maintain audit trails",
  "Support reproducibility."
  """

  def record_deployment(authorization_id, deployment_id, path) do
    File.mkdir_p!(Path.dirname(path))
    entry = {authorization_id, deployment_id, System.system_time(:millisecond)}
    serialized = :erlang.term_to_binary(entry)
    File.write(path, [<<byte_size(serialized)::32>>, serialized], [:append])
  end

  def already_deployed?(authorization_id, path) do
    case File.read(path) do
      {:ok, content} ->
        content
        |> decode_records()
        |> Enum.any?(fn {aid, _did, _ts} -> aid == authorization_id end)

      _ ->
        false
    end
  end

  defp decode_records(<<>>), do: []

  defp decode_records(<<size::32, term::binary-size(size), rest::binary>>) do
    [:erlang.binary_to_term(term) | decode_records(rest)]
  end

  defp decode_records(_truncated), do: []
end