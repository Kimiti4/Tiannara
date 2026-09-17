defmodule Tiannara.Meta.OPC.Mesh.OPCMeshSync do
  @moduledoc """
  Phase 5F.6 — OPC Mesh Sync

  Distributes compiled GPU kernels across the NATS mesh so that all
  runtime nodes execute the same observer physics. Publishes to the
  `tiannara.mesh.shader.sync` subject.

  ## Usage

      kernel = %{observer_id: "obs_001", shader: "...", kernel_id: "k_42"}
      :ok = OPCMeshSync.synchronize(kernel)
  """

  require Logger

  @nats_conn :tiannara_nats
  @subject "tiannara.mesh.shader.sync"

  @doc """
  Publishes a compiled kernel to the mesh for distribution.

  ## Parameters
  - `kernel`: Map containing at least `:observer_id`, `:kernel_id`, `:shader`

  ## Returns
  - `:ok` — Published (or logged locally when NATS is unavailable)
  - `{:error, reason}` — Publish failed
  """
  def synchronize(kernel) when is_map(kernel) do
    encoded = Jason.encode!(kernel)

    case Process.whereis(@nats_conn) do
      nil ->
        Logger.debug("[OPCMeshSync] NATS unavailable — kernel logged locally")
        Logger.debug("[NATS] #{@subject}: #{String.slice(encoded, 0, 120)}...")
        :ok

      _pid ->
        case Gnat.pub(@nats_conn, @subject, encoded) do
          :ok ->
            Logger.info("🌐 [OPCMeshSync] Kernel #{kernel[:kernel_id]} synced to mesh")
            :ok

          {:error, reason} ->
            Logger.error("🛑 [OPCMeshSync] Sync failed: #{inspect(reason)}")
            {:error, reason}
        end
    end
  end
end
