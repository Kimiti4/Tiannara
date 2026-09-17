{:ok, _} = Application.ensure_all_started(:tiannara)
Process.sleep(800)
# Ensure the extra capability is registered (in case this is a fresh VM)
case Tiannara.CEL.Services.CapabilityRegistry.find_provider(:bayes_update) do
  {:error, :no_provider} ->
    Tiannara.CEL.Services.CapabilityRegistry.register_capability(:constitutional_mathematics, [:bayes_update], self())
    Process.sleep(200)
  _ -> :ok
end
IO.puts("All providers: #{inspect(Tiannara.CEL.Services.CapabilityRegistry.all_providers())}")
IO.puts("Find create_capability: #{inspect(Tiannara.CEL.Services.CapabilityRegistry.find_provider(:create_capability))}")
IO.puts("Find bayes_update: #{inspect(Tiannara.CEL.Services.CapabilityRegistry.find_provider(:bayes_update))}")
IO.puts("Find capability_adaptation: #{inspect(Tiannara.CEL.Services.CapabilityRegistry.find_provider(:capability_adaptation))}")
IO.puts("Find bayesian_update: #{inspect(Tiannara.CEL.Services.CapabilityRegistry.find_provider(:bayesian_update))}")
