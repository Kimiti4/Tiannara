defmodule Tiannara.Meta.OPC.Runtime.GPUDispatcher do
  @moduledoc """
  Phase 5F.6 — GPU Dispatcher

  Dispatches compiled GLSL shaders to the GPU execution layer via NATS
  JetStream. In production the TypeScript WebGL2 runtime subscribes to
  `tiannara.opc.execute` and executes the kernel on the GPU.

  ## NATS subject

      tiannara.opc.execute

  ## Payload schema

      %{
        observer_id: String.t(),
        kernel_id:   String.t(),
        uniforms:    map()
      }

  ## Usage

      {:ok, result} = GPUDispatcher.dispatch("obs_001", shader_source, %{})
  """

  require Logger

  @nats_conn :tiannara_nats
  @subject "tiannara.opc.execute"

  @doc """
  Dispatches a compiled shader to the GPU runtime.

  ## Parameters
  - `observer_id`: Observer identifier
  - `shader`:      GLSL source string
  - `uniforms`:    Map of uniform values to bind

  ## Returns
  - `{:ok, result}` — Dispatch succeeded
  - `{:error, reason}` — Dispatch failed
  """
  def dispatch(observer_id, shader, uniforms) when is_binary(shader) do
    kernel_id = generate_kernel_id(observer_id)

    payload = %{
      observer_id: observer_id,
      kernel_id: kernel_id,
      shader: shader,
      uniforms: uniforms
    }

    case publish(payload) do
      :ok ->
        Logger.info("⚡ [GPUDispatcher] Kernel #{kernel_id} dispatched for #{observer_id}")

        result = %{
          observer_id: observer_id,
          kernel_id: kernel_id,
          status: :dispatched,
          dispatched_at: System.system_time(:millisecond)
        }

        {:ok, result}

      {:error, reason} ->
        Logger.error("🛑 [GPUDispatcher] Dispatch failed for #{observer_id}: #{inspect(reason)}")
        {:error, reason}
    end
  end

  # ── Private Functions ─────────────────────────────────────────────────────

  defp publish(payload) do
    encoded = Jason.encode!(payload)

    case Process.whereis(@nats_conn) do
      nil ->
        # NATS not running — log and succeed silently in dev/test
        Logger.debug("[GPUDispatcher] NATS unavailable, logging payload locally")
        Logger.debug("[NATS] #{@subject}: #{String.slice(encoded, 0, 120)}...")
        :ok

      _pid ->
        Gnat.pub(@nats_conn, @subject, encoded)
    end
  end

  defp generate_kernel_id(observer_id) do
    ts = System.system_time(:millisecond)
    "kernel_#{observer_id}_#{ts}"
  end
end
