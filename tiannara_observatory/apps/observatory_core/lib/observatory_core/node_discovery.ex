defmodule ObservatoryCore.NodeDiscovery do
  @cluster_env :observatory_core

  def discover do
    case Application.get_env(@cluster_env, :cluster_mode, :standalone) do
      :standalone -> [Node.self()]
      :dns -> discover_dns()
      :kubernetes -> discover_k8s()
    end
  end

  defp discover_dns do
    dns_name = Application.get_env(@cluster_env, :dns_name, "observatory.local")

    case :inet_res.lookup(to_charlist(dns_name), :in, :a) do
      {:ok, addresses} -> Enum.map(addresses, fn _ -> Node.self() end)
      _ -> [Node.self()]
    end
  end

  defp discover_k8s, do: [Node.self()]
end
