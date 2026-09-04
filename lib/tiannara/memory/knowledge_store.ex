defmodule Tiannara.Memory.KnowledgeStore do
  @moduledoc """
  Isolated, append-only store for promoted knowledge. NOT production memory.

  ISOLATION CONTRACT:
    Writes go to an isolated directory and MUST refuse the production memory
    path. Promoted artifacts preserve lineage so they can later be reviewed
    and merged into production memory through a deliberate, validated process
    — never silently.

  Constitutional basis: "Preserve lineage", "Maintain audit trails",
  "Capability must never outpace verification."
  """

  @production_memory_path "memory/production"

  alias Tiannara.Memory.Artifact

  defstruct [:data_dir]

  def open(data_dir) do
    with :ok <- ensure_not_production(data_dir),
         :ok <- File.mkdir_p(data_dir) do
      {:ok, %__MODULE__{data_dir: data_dir}}
    end
  end

  defp ensure_not_production(data_dir) do
    normalized = Path.expand(data_dir)
    prod = Path.expand(@production_memory_path)

    if normalized == prod or String.starts_with?(normalized, prod <> "/") do
      {:error, :production_memory_forbidden}
    else
      :ok
    end
  end

  def append(%__MODULE__{data_dir: dir}, %Artifact{} = artifact) do
    File.write(Path.join(dir, "#{artifact.id}.etf"), :erlang.term_to_binary(artifact))
  end

  def append_chain(%__MODULE__{} = store, chain) when is_list(chain) do
    Enum.each(chain, &append(store, &1))
    :ok
  end

  def all(%__MODULE__{data_dir: dir}) do
    dir
    |> File.ls!()
    |> Enum.filter(&String.ends_with?(&1, ".etf"))
    |> Enum.map(fn name ->
      dir |> Path.join(name) |> File.read!() |> :erlang.binary_to_term()
    end)
  end
end
