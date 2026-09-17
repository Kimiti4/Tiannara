defmodule TiannaraRuntime.CrossDimensional.PortalProtocol do
  @moduledoc """
  Phase 5F.12 — CrossDimensional Portal Protocol

  Publishes meta-op portal events into the DFG execution fabric.
  """

  use GenServer
  require Logger
  alias TiannaraRuntime.NATS.Publisher

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    {:ok, %{published: 0}}
  end

  @portal_subject "tiannara.cross_dimensional.meta_op"

  def publish(meta_op, bytecode) when is_map(meta_op) and is_binary(bytecode) do
    payload = %{
      event: :meta_op_published,
      meta_op_id: Map.get(meta_op, :id),
      anchor_count: length(Map.get(meta_op, :anchors, [])),
      cost_estimate: Map.get(meta_op, :cost_estimate),
      published_at: DateTime.utc_now() |> DateTime.to_iso8601(),
      bytecode_size: byte_size(bytecode)
    }

    Logger.info("[CrossDimensional] Publishing meta-op #{Map.get(meta_op, :id)} to #{@portal_subject}")
    Publisher.publish(@portal_subject, Jason.encode!(payload))
    {:ok, payload}
  end
end
