defmodule TiannaraRuntime.Layer do
  @moduledoc """
  Lightweight authority declaration and guard checks for cross-layer calls.
  """

  defmacro __using__(opts) do
    authority = Keyword.fetch!(opts, :authority)
    can_call = Keyword.get(opts, :can_call, [])
    can_receive = Keyword.get(opts, :can_receive, [])

    quote do
      @tiannara_authority unquote(authority)
      @tiannara_can_call unquote(can_call)
      @tiannara_can_receive unquote(can_receive)

      def tiannara_layer_meta do
        %{
          authority: @tiannara_authority,
          can_call: @tiannara_can_call,
          can_receive: @tiannara_can_receive
        }
      end
    end
  end

  def allow_call?(from, to) do
    direction = %{
      meta: [:constraint],
      constraint: [:ecology, :execution],
      ecology: [:execution],
      execution: []
    }

    to in Map.get(direction, from, [])
  end

  def assert_call!(from, to) do
    if allow_call?(from, to) do
      :ok
    else
      raise "Forbidden cross-layer call #{inspect(from)} -> #{inspect(to)}"
    end
  end
end
