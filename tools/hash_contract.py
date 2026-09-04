#!/usr/bin/env python3
"""
Hash a certification contract for freezing.
Produces a deterministic SHA-256 hash of the canonical contract content.
"""

import sys
import yaml
import hashlib
import json
from pathlib import Path

def canonicalize(term):
    """Canonicalize a term for deterministic hashing."""
    if isinstance(term, dict):
        return {str(k): canonicalize(v) for k, v in sorted(term.items())}
    elif isinstance(term, list):
        return [canonicalize(v) for v in term]
    else:
        return term

def hash_contract(contract_path: Path) -> str:
    """Compute the canonical hash of a contract."""
    with open(contract_path, 'r') as f:
        contract = yaml.safe_load(f)
    
    # Remove contract_hash field before hashing (it's what we're computing)
    contract_for_hash = {k: v for k, v in contract.items() if k != 'contract_hash'}
    
    # Canonicalize
    canonical = canonicalize(contract_for_hash)
    
    # Encode as JSON with sorted keys
    json_str = json.dumps(canonical, sort_keys=True, separators=(',', ':'))
    
    # Hash
    return hashlib.sha256(json_str.encode('utf-8')).hexdigest()

def update_contract_hash(contract_path: Path) -> None:
    """Update the contract_hash field in the contract file."""
    hash_value = hash_contract(contract_path)
    
    with open(contract_path, 'r') as f:
        content = f.read()
    
    # Replace contract_hash: null with contract_hash: <hash>
    import re
    updated = re.sub(
        r'contract_hash:\s*null',
        f'contract_hash: "{hash_value}"',
        content
    )
    
    with open(contract_path, 'w') as f:
        f.write(updated)
    
    print(f"Contract hash: {hash_value}")
    print(f"Updated: {contract_path}")

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: python hash_contract.py <contract_path>")
        sys.exit(1)
    
    contract_path = Path(sys.argv[1])
    if not contract_path.exists():
        print(f"Contract not found: {contract_path}")
        sys.exit(1)
    
    update_contract_hash(contract_path)
