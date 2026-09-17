defmodule TiannaraRuntime.Civilization.Runtime.KnowledgeRuntime do
  def initialize() do
    {:ok, %{repositories: [], proofs: [], theories: [], world_models: [], scientific_assets: []}}
  end

  def add_discovery(runtime, discovery) do
    type = Map.get(discovery, :type, :repositories)
    key = list_key(type)
    current = Map.get(runtime, key, [])
    {:ok, Map.put(runtime, key, [discovery | current])}
  end

  def add_proof(runtime, proof) do
    {:ok, %{runtime | proofs: [proof | runtime.proofs]}}
  end

  def query(runtime, domain) do
    all = runtime.repositories ++ runtime.proofs ++ runtime.theories ++ runtime.world_models ++ runtime.scientific_assets
    filtered = Enum.filter(all, fn item -> Map.get(item, :domain) == domain end)
    {:ok, filtered}
  end

  def metrics(runtime) do
    {:ok, %{
      repositories: length(runtime.repositories),
      proofs: length(runtime.proofs),
      theories: length(runtime.theories),
      world_models: length(runtime.world_models),
      scientific_assets: length(runtime.scientific_assets)
    }}
  end

  defp list_key(:repositories), do: :repositories
  defp list_key(:proofs), do: :proofs
  defp list_key(:theories), do: :theories
  defp list_key(:world_models), do: :world_models
  defp list_key(:scientific_assets), do: :scientific_assets
  defp list_key(_), do: :repositories
end
