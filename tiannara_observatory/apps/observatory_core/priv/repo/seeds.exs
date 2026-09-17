# Observatory Core — Dev Seed Script
#
# Run: mix run apps/observatory_core/priv/repo/seeds.exs

IO.puts("[Seed] Bootstrapping observatory identities...")

identities = Rbac.Identity.seed()

Enum.each(identities, fn {_name, ident} ->
  Rbac.Engine.register_identity(ident)
  IO.puts("  ✓ Registered identity: #{ident.name} (#{ident.type})")
end)

IO.puts("[Seed] Generating initial config artifact...")
config = ObservatoryCore.Config.load!()
IO.puts("  ✓ Config artifact stored (env=#{config.env})")

IO.puts("[Seed] Recording genesis audit entry...")
{:ok, entry} = Rbac.Audit.Ledger.record(%{
  actor: "seed-script",
  action: "SEED",
  resource: "observatory",
  intent: "bootstrap",
  evidence: "Dev seed script execution",
  decision: "granted",
  result: "bootstrapped"
})
IO.puts("  ✓ Genesis audit entry: #{entry.current_hash}")

IO.puts("[Seed] Observatory bootstrap complete.")
