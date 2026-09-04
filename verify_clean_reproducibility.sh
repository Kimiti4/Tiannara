#!/usr/bin/env bash
# Clean Repository Reproducibility Test - Phase 14 RC3
# This script clones the repository fresh and verifies certificate hashes match

set -e

REPO_URL="${1:-.}"
CLONE_DIR="${2:-/tmp/tiannara_clean_clone_$$}"
REFERENCE_HASH_FILE="phase14/certification/hashes/reference_hashes.json"

echo "🧪 Clean Repository Reproducibility Test"
echo "=========================================="
echo ""
echo "Repository: $REPO_URL"
echo "Clone directory: $CLONE_DIR"
echo ""

# Step 1: Clean up any previous clone
if [ -d "$CLONE_DIR" ]; then
    echo "🗑️  Removing previous clone..."
    rm -rf "$CLONE_DIR"
fi

# Step 2: Clone repository
echo "📦 Cloning repository..."
git clone "$REPO_URL" "$CLONE_DIR" --depth 1
cd "$CLONE_DIR"

# Step 3: Install dependencies
echo "📚 Installing dependencies..."
mix deps.get --only prod

# Step 4: Compile
echo "🔨 Compiling..."
mix compile

# Step 5: Generate evidence package
echo "🎯 Generating evidence package..."
mix run generate_phase14_evidence_package.exs

# Step 6: Extract hashes from generated package
echo "🔍 Extracting certificate hashes..."
GENERATED_HASH_FILE="$CLONE_DIR/phase14/certification/hashes/evidence_index.json"

if [ ! -f "$GENERATED_HASH_FILE" ]; then
    echo "❌ ERROR: Generated hash file not found!"
    exit 1
fi

# Step 7: Compare with reference hashes (if available)
if [ -f "$REFERENCE_HASH_FILE" ]; then
    echo "⚖️  Comparing with reference hashes..."
    
    # Use Python to compare JSON files (more reliable than jq for complex structures)
    python3 << 'PYTHON_SCRIPT'
import json
import sys

try:
    with open('phase14/certification/hashes/reference_hashes.json', 'r') as f:
        reference = json.load(f)
    
    with open('phase14/certification/hashes/evidence_index.json', 'r') as f:
        generated = json.load(f)
    
    # Compare file counts
    if len(reference) != len(generated):
        print(f"❌ File count mismatch: {len(reference)} vs {len(generated)}")
        sys.exit(1)
    
    # Build lookup maps
    ref_map = {item['file']: item['sha256'] for item in reference}
    gen_map = {item['file']: item['sha256'] for item in generated}
    
    # Compare each file's hash
    mismatches = []
    for file_path, ref_hash in ref_map.items():
        if file_path not in gen_map:
            mismatches.append(f"Missing file: {file_path}")
        elif ref_hash != gen_map[file_path]:
            mismatches.append(f"Hash mismatch for {file_path}:")
            mismatches.append(f"  Reference:  {ref_hash}")
            mismatches.append(f"  Generated:  {gen_map[file_path]}")
    
    if mismatches:
        print("❌ Hash verification FAILED:")
        for line in mismatches:
            print(line)
        sys.exit(1)
    else:
        print(f"✅ All {len(reference)} file hashes match perfectly!")
        print("✅ Clean repository reproducibility VERIFIED")
        
except Exception as e:
    print(f"❌ Error during comparison: {e}")
    sys.exit(1)
PYTHON_SCRIPT
    
else
    echo "⚠️  No reference hash file found at $REFERENCE_HASH_FILE"
    echo "💡 Saving current hashes as reference for future comparisons..."
    cp "$GENERATED_HASH_FILE" "$REFERENCE_HASH_FILE"
    echo "✅ Reference hashes saved"
fi

# Step 8: Cleanup
echo ""
echo "🧹 Cleaning up clone directory..."
cd /
rm -rf "$CLONE_DIR"

echo ""
echo "✅ Clean Repository Reproducibility Test COMPLETE"
echo ""
