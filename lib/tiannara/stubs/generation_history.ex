defmodule GenerationHistory do
  @moduledoc "Compatibility API for generation history metrics."

  def new(opts \\ %{}), do: TiannaraOS.Kernel.GenerationHistory.new(opts)

  def calculate_cai(sample) when is_map(sample) do
    values = sample |> Map.values() |> Enum.filter(&is_number/1)
    score = if values == [], do: 0.0, else: values |> Enum.map(&abs/1) |> Enum.sum() / length(values)
    Float.round(min(score, 1.0), 6)
  end
  def calculate_cai(_), do: 0.0

  def append_to_file(history, file_path) when is_binary(file_path) do
    payload = Jason.encode!(history)
    case File.write(file_path, payload <> "\n", [:append]) do
      :ok -> :ok
      {:error, reason} -> {:error, reason}
    end
  end
end
