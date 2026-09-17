alias TiannaraRuntime.Mathematics.Validation.Validator

IO.puts("""
╔══════════════════════════════════════════════════════════════╗
║  Phase 16.X.95 — Constitutional Mathematics Validation      ║
║  Running all 10 campaigns...                                ║
╚══════════════════════════════════════════════════════════════╝
""")

result = Validator.run(
  campaigns: [:contract, :replay, :serialization, :proof, :conjecture,
              :verification, :runtime, :stress, :failure_injection, :archaeology],
  timeout: 180_000
)

IO.puts(Validator.summary(result))
Validator.generate_reports(result)
IO.puts("\nReports generated in priv/validation_reports/")

