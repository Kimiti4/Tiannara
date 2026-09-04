defmodule Tiannara.Math.Statistics do
  def mean([]), do: {:error, :empty_dataset}
  def mean(data), do: {:ok, Enum.sum(data) / length(data)}

  def variance([]), do: {:error, :empty_dataset}
  def variance(data) do
    {:ok, mu} = mean(data)
    sq_diff = Enum.reduce(data, 0.0, fn x, acc -> acc + :math.pow(x - mu, 2) end)
    {:ok, sq_diff / length(data)}
  end

  def standard_deviation(data) do
    with {:ok, var} <- variance(data), do: {:ok, :math.sqrt(var)}
  end
end
