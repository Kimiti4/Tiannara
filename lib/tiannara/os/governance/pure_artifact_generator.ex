defmodule TiannaraOS.Governance.PureArtifactGenerator do
  @moduledoc """
  PureArtifactGenerator - Generates certification artifacts with zero runtime state leakage.
  
  This module ensures that all certification outputs are purely deterministic by:
  1. Using DeterministicContext for all randomness and timestamps
  2. Sorting all collections deterministically before serialization
  3. Excluding non-deterministic metadata (actual wall-clock time, PIDs, etc.)
  4. Producing identical output for identical inputs across runs
  
  ## Constitutional Principle
  
  **Artifacts must be reproducible from source alone.** No hidden state, no
  environment dependence, no implicit ordering. The same git commit on any
  machine must produce byte-identical artifacts.
  
  ## Usage
  
      # Generate full certification package deterministically
      {:ok, package} = PureArtifactGenerator.generate(seed: 42)
      
      # Verify reproducibility by running twice
      {:ok, pkg1} = PureArtifactGenerator.generate(seed: 42)
      {:ok, pkg2} = PureArtifactGenerator.generate(seed: 42)
      
      hash1 = :crypto.hash(:sha256, Jason.encode!(pkg1)) |> Base.encode16()
      hash2 = :crypto.hash(:sha256, Jason.encode!(pkg2)) |> Base.encode16()
      
      # These MUST match
      hash1 == hash2  # true
      
      # Different seeds produce different but reproducible results
      {:ok, pkg3} = PureArtifactGenerator.generate(seed: 99)
      hash3 = :crypto.hash(:sha256, Jason.encode!(pkg3)) |> Base.encode16()
      hash1 != hash3  # true (different seed)
  """
  
  alias TiannaraOS.Governance.{
    Certification.Laboratory,
    DeterministicContext
  }
  
  @type generation_result :: {:ok, map()} | {:error, term()}
  
  @doc """
  Generate complete certification artifact package.
  
  ## Options
  
  - `:seed` - Random seed for deterministic execution (integer). Default: 42
  - `:base_time` - Base timestamp for all operations. Default: 2026-01-01T00:00:00Z
  - `:output_dir` - Directory to save artifacts. Default: "phase14/certification"
  
  ## Returns
  
  {:ok, %{certificate: cert, manifest: manifest, hashes: hashes}} or {:error, reason}
  """
  @spec generate(keyword()) :: generation_result()
  def generate(opts \\ []) do
    seed = Keyword.get(opts, :seed, 42)
    base_time = Keyword.get(opts, :base_time, ~U[2026-01-01 00:00:00Z])
    output_dir = Keyword.get(opts, :output_dir, "phase14/certification")
    
    IO.puts("\n🎯 Pure Artifact Generation")
    IO.puts("═══════════════════════════════════════")
    IO.puts("Seed: #{seed}")
    IO.puts("Base Time: #{DateTime.to_iso8601(base_time)}")
    IO.puts("Output: #{output_dir}")
    IO.puts("")
    
    # Create deterministic context
    ctx = DeterministicContext.new(seed: seed, base_time: base_time)
    
    # Execute certification with deterministic context
    IO.puts("📊 Executing certification campaigns...")
    case Laboratory.execute_certification(context: ctx) do
      {:ok, certificate} ->
        IO.puts("✅ Certification complete")
        
        # Build deterministic manifest
        IO.puts("📋 Building manifest...")
        manifest = build_manifest(certificate, ctx)
        
        # Compute hashes
        IO.puts("🔐 Computing SHA-256 hashes...")
        hashes = compute_hashes(certificate, manifest)
        
        # Save artifacts
        IO.puts("💾 Saving artifacts to #{output_dir}...")
        :ok = save_artifacts(output_dir, certificate, manifest, hashes)
        
        result = %{
          certificate: certificate,
          manifest: manifest,
          hashes: hashes,
          seed: seed,
          base_time: DateTime.to_iso8601(base_time),
          generated_at: DateTime.to_iso8601(DateTime.utc_now()),  # For logging only, not in artifacts
          output_dir: output_dir
        }
        
        IO.puts("\n✅ Pure artifact generation complete!")
        IO.puts("   Certificate SHA-256: #{hashes.certificate_sha256}")
        IO.puts("   Manifest SHA-256: #{hashes.manifest_sha256}")
        
        {:ok, result}
        
      {:error, reason} ->
        IO.puts("❌ Certification failed: #{inspect(reason)}")
        {:error, reason}
    end
  end
  
  @doc """
  Verify artifact integrity by recomputing hashes.
    
  Returns {:ok, verified} if all hashes match, or {:error, mismatches}.
  """
  @spec verify_artifact_integrity(String.t()) :: {:ok, boolean()} | {:error, [String.t()]}
  def verify_artifact_integrity(output_dir \\ "phase14/certification") do
    cert_path = Path.join(output_dir, "certificate.json")
    sig_path = Path.join(output_dir, "certificate.sha256")
    manifest_path = Path.join(output_dir, "manifest.json")
    hashes_path = Path.join(output_dir, "hashes.json")
      
    # Load stored hashes
    stored_hashes = case File.read(hashes_path) do
      {:ok, content} -> Jason.decode!(content)
      {:error, _} -> return_error("Could not read hashes file")
    end
      
    # Recompute certificate hash from payload only
    cert_content = case File.read(cert_path) do
      {:ok, content} -> content
      {:error, _} -> return_error("Could not read certificate file")
    end
    computed_cert_hash = :crypto.hash(:sha256, cert_content) |> Base.encode16(case: :lower)
      
    # Verify signature file matches if present
    cert_sig_valid = case File.read(sig_path) do
      {:ok, sig_content} ->
        stored_sig = String.trim(sig_content)
        stored_sig == stored_hashes["certificate_sha256"]
      {:error, _} -> true  # Signature file is optional
    end
      
    # Recompute manifest hash
    manifest_content = case File.read(manifest_path) do
      {:ok, content} -> content
      {:error, _} -> return_error("Could not read manifest file")
    end
    computed_manifest_hash = :crypto.hash(:sha256, manifest_content) |> Base.encode16(case: :lower)
      
    # Compare
    mismatches = []
    mismatches = if computed_cert_hash != stored_hashes["certificate_sha256"] do
      ["Certificate hash mismatch"] ++ mismatches
    else
      mismatches
    end
      
    mismatches = if not cert_sig_valid do
      ["Certificate signature mismatch"] ++ mismatches
    else
      mismatches
    end
      
    mismatches = if computed_manifest_hash != stored_hashes["manifest_sha256"] do
      ["Manifest hash mismatch"] ++ mismatches
    else
      mismatches
    end
      
    if Enum.empty?(mismatches) do
      {:ok, true}
    else
      {:error, mismatches}
    end
  end
  
  # ============================================================================
  # Private Functions
  # ============================================================================
  
  defp build_manifest(certificate, ctx) do
    {timestamp, _ctx2} = DeterministicContext.next_timestamp(ctx)
    
    %{
      version: "14.0.999",
      type: :pure_artifact_package,
      generated_by: "PureArtifactGenerator",
      deterministic_seed: ctx.seed,
      base_time: DateTime.to_iso8601(ctx.base_time),
      timestamp: DateTime.to_iso8601(timestamp),
      campaigns_executed: Map.get(certificate, :campaigns_executed, 0),
      campaigns_passed: Map.get(certificate, :campaigns_passed, 0),
      campaigns_failed: Map.get(certificate, :campaigns_failed, 0),
      certification_status: Map.get(certificate, :certification_status, :unknown),
      governance_version: Map.get(certificate, :governance_version, "unknown"),
      artifacts: [
        "certificate.json",
        "manifest.json",
        "hashes.json"
      ]
    }
  end
  
  defp compute_hashes(certificate, manifest) do
    # Extract payload for hashing (separated from signature)
    cert_payload = Map.get(certificate, :payload, certificate)
    
    payload_json = Jason.encode!(cert_payload, pretty: true)
    manifest_json = Jason.encode!(manifest, pretty: true)
    
    cert_hash = :crypto.hash(:sha256, payload_json) |> Base.encode16(case: :lower)
    manifest_hash = :crypto.hash(:sha256, manifest_json) |> Base.encode16(case: :lower)
    
    %{
      certificate_sha256: cert_hash,
      manifest_sha256: manifest_hash,
      certificate_size_bytes: byte_size(payload_json),
      manifest_size_bytes: byte_size(manifest_json)
    }
  end
  
  defp save_artifacts(output_dir, certificate, manifest, hashes) do
    # Create directory structure
    File.mkdir_p!(output_dir)
    
    # Extract payload and signature from certificate (separated structure)
    cert_payload = Map.get(certificate, :payload, certificate)
    
    # Convert payload to JSON for hashing and saving
    payload_json = Jason.encode!(cert_payload, pretty: true)
    manifest_json = Jason.encode!(manifest, pretty: true)
    hashes_json = Jason.encode!(hashes, pretty: true)
    
    # Compute signature from actual JSON bytes (not pre-computed)
    cert_signature = :crypto.hash(:sha256, payload_json) |> Base.encode16(case: :lower)
    
    # Save certificate payload (without signature embedded)
    payload_path = Path.join(output_dir, "certificate.json")
    File.write!(payload_path, payload_json)
    
    # Save certificate signature separately
    sig_path = Path.join(output_dir, "certificate.sha256")
    File.write!(sig_path, cert_signature <> "\n")
    
    # Save manifest
    manifest_path = Path.join(output_dir, "manifest.json")
    File.write!(manifest_path, manifest_json)
    
    # Save hashes
    hashes_path = Path.join(output_dir, "hashes.json")
    File.write!(hashes_path, hashes_json)
    
    :ok
  end
  
  defp return_error(msg), do: {:error, msg}
end
