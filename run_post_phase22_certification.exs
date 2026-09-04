Mix.install([])

alias TiannaraOS.Governance.Certification.CampaignOrchestrator

# Configurable via environment variables:
# TIANNARA_SCALE - :quick | :standard | :full (default: :standard)
# TIANNARA_SEED - integer (default: generated)
# TIANNARA_DOMAIN - run specific domain (e.g. constitutional_integrity)
# TIANNARA_CAMPAIGN_FILTER - run specific campaigns (e.g. "1,3,14")

scale = case System.get_env("TIANNARA_SCALE") do
  "quick" -> :quick
  "full" -> :full
  _ -> :standard
end

seed = case System.get_env("TIANNARA_SEED") do
  nil -> :erlang.phash2(System.system_time())
  val -> String.to_integer(val)
end

opts = [scale: scale, seed: seed]

opts = case System.get_env("TIANNARA_DOMAIN") do
  nil -> opts
  domain_str -> Keyword.put(opts, :domain, String.to_atom(domain_str))
end

opts = case System.get_env("TIANNARA_CAMPAIGN_FILTER") do
  nil -> opts
  filter_str ->
    campaigns = filter_str |> String.split(",") |> Enum.map(&String.trim/1) |> Enum.map(&String.to_integer/1)
    Keyword.put(opts, :campaign_filter, campaigns)
end

case CampaignOrchestrator.run_all(opts) do
  {:ok, certificate} ->
    IO.puts("\n✅ Certification complete. Certificate status: #{certificate.status}")
    System.halt(0)
  {:error, _reason, _results} ->
    IO.puts("\n❌ Certification failed. Check logs for details.")
    System.halt(1)
end
