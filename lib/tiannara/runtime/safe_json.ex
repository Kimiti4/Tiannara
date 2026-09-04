defmodule Tiannara.Runtime.SafeJSON do
  def encode!(term) do
    term |> sanitize() |> Jason.encode!()
  end

  def encode(term) do
    {:ok, sanitize(term)} |> Jason.encode()
  end

  defp sanitize(%DateTime{} = dt), do: DateTime.to_iso8601(dt)
  defp sanitize(%Date{} = d), do: Date.to_iso8601(d)
  defp sanitize(%Time{} = t), do: Time.to_iso8601(t)
  defp sanitize(pid) when is_pid(pid), do: inspect(pid)
  defp sanitize(ref) when is_reference(ref), do: inspect(ref)
  defp sanitize(port) when is_port(port), do: inspect(port)
  defp sanitize(fun) when is_function(fun), do: "#Function<#{:erlang.fun_info(fun, :arity)}>"
  defp sanitize(map) when is_map(map), do: Map.new(map, fn {k, v} -> {sanitize(k), sanitize(v)} end)
  defp sanitize(list) when is_list(list), do: Enum.map(list, &sanitize/1)
  defp sanitize(tuple) when is_tuple(tuple), do: tuple |> Tuple.to_list() |> Enum.map(&sanitize/1) |> List.to_tuple()
  defp sanitize(term), do: term
end
