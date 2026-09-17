defmodule TiannaraRuntime.NATS.JetStreamHelper do
  @moduledoc """
  Shared helper for ensuring JetStream streams exist across phase supervisors.
  Consolidates identical `ensure_jetstream_stream/0` logic that was copy-pasted
  across 9 phase supervisor files.
  """

  require Logger

  @doc """
  Ensures a JetStream stream exists with the given name and config.
  Returns `:ok` regardless of outcome (graceful degradation).
  """
  @spec ensure_stream(atom(), keyword()) :: :ok
  def ensure_stream(conn, config) do
    stream_name = Keyword.fetch!(config, :name)
    subjects = Keyword.fetch!(config, :subjects)
    max_msgs = Keyword.get(config, :max_msgs, 1_000_000)

    if Code.ensure_loaded?(Gnat.JetStream) do
      case Gnat.JetStream.stream_info(conn, stream_name) do
        {:ok, _} ->
          :ok

        {:error, :not_found} ->
          Gnat.JetStream.add_stream(conn, %{
            name: stream_name,
            subjects: subjects,
            retention: :limits,
            max_msgs: max_msgs,
            storage: :file,
            replicas: 3
          })

        {:error, _} ->
          :ok
      end
    else
      Logger.warning("Gnat.JetStream not available, skipping stream '#{stream_name}' setup")
      :ok
    end
  end
end
