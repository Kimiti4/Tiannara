defmodule Tiannara.NATS.OPCBus do
  require Logger
  alias TiannaraRuntime.NATS.Publisher

  @compile_topic "tiannara.opc.compile"
  @validate_topic "tiannara.opc.validate"
  @shader_build_topic "tiannara.opc.shader.build"
  @execute_topic "tiannara.opc.execute"
  @execution_result_topic "tiannara.opc.execution.result"
  @rollback_topic "tiannara.opc.rollback"

  def publish_compile_request(payload) do
    message = %{
      type: :compile_request,
      payload: payload,
      timestamp: System.system_time(:millisecond),
      trace_id: generate_trace_id()
    }
    Publisher.publish(@compile_topic, Jason.encode!(message))
    :ok
  end

  def publish_validation_result(observer_id, validation_result) do
    coerced_result =
      case validation_result do
        {:error, reason} -> ["error", to_string(reason)]
        other -> other
      end
    message = %{
      type: :validation_result,
      observer_id: observer_id,
      result: coerced_result,
      timestamp: System.system_time(:millisecond)
    }
    Publisher.publish(@validate_topic, Jason.encode!(message))
    :ok
  end

  def publish_shader_built(observer_id, shader_id, shader_size) do
    message = %{
      type: :shader_built,
      observer_id: observer_id,
      shader_id: shader_id,
      shader_size: shader_size,
      timestamp: System.system_time(:millisecond)
    }
    Publisher.publish(@shader_build_topic, Jason.encode!(message))
    :ok
  end

  def publish_execute(observer_id, shader_id, uniforms \\ %{}) do
    message = %{
      type: :execute,
      observer_id: observer_id,
      shader_id: shader_id,
      uniforms: uniforms,
      timestamp: System.system_time(:millisecond)
    }
    Publisher.publish(@execute_topic, Jason.encode!(message))
    :ok
  end

  def publish_execution_result(observer_id, execution_id, result) do
    message = %{
      type: :execution_result,
      observer_id: observer_id,
      execution_id: execution_id,
      result: result,
      timestamp: System.system_time(:millisecond)
    }
    Publisher.publish(@execution_result_topic, Jason.encode!(message))
    :ok
  end

  def publish_rollback(observer_id, reason) do
    message = %{
      type: :rollback,
      observer_id: observer_id,
      reason: reason,
      timestamp: System.system_time(:millisecond)
    }
    Publisher.publish(@rollback_topic, Jason.encode!(message))
    :ok
  end

  def subscribe_compile_requests(callback) do
    TiannaraRuntime.NATS.Bus.subscribe(@compile_topic)
    {:ok, :subscription_stub}
  end

  def subscribe_execution_results(callback) do
    TiannaraRuntime.NATS.Bus.subscribe(@execution_result_topic)
    {:ok, :subscription_stub}
  end

  defp generate_trace_id do
    UUID.uuid4()
  end
end
