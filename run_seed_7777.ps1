$env:SEED='7777'
mix run run_pure_artifact_generator.exs 2>&1 | Select-String "Certificate SHA-256"
