"""
Certification bounds enforcement for Tiannara certification probes.
Ensures probes operate within constitutional boundaries.
"""

import yaml
from pathlib import Path
from typing import Dict, Any

class CertificationContractError(Exception):
    """Raised when certification contract is invalid."""
    pass

class ActionNotCertificationError(Exception):
    """Raised when an action violates certification bounds."""
    pass

def load_certification_contract(contract_path: Path) -> Dict[str, Any]:
    """Load and parse certification contract YAML."""
    if not contract_path.exists():
        raise CertificationContractError(f"Contract not found: {contract_path}")
    
    with open(contract_path, 'r') as f:
        contract = yaml.safe_load(f)
    
    # Validate required fields
    required = ['probe_id', 'mode', 'class', 'bounded_proposition', 
                'production_mutation_allowed', 'registry_mutation_allowed',
                'external_mutations_allowed', 'production_adoption_allowed',
                'egress_mode', 'verdict_space', 'verdict_rules']
    
    for field in required:
        if field not in contract:
            raise CertificationContractError(f"Missing required field: {field}")
    
    return contract

def enforce_certification_bounds(contract: Dict[str, Any]) -> None:
    """Enforce certification bounds from contract."""
    
    # Check mode is CERTIFICATION
    if contract.get('mode') != 'CERTIFICATION':
        raise ActionNotCertificationError(f"Invalid mode: {contract.get('mode')}. Must be CERTIFICATION.")
    
    # Check production mutation is not allowed
    if contract.get('production_mutation_allowed') is True:
        raise ActionNotCertificationError("Production mutation not allowed in certification mode.")
    
    # Check registry mutation is not allowed
    if contract.get('registry_mutation_allowed') is True:
        raise ActionNotCertificationError("Registry mutation not allowed in certification mode.")
    
    # Check external mutations not allowed
    if contract.get('external_mutations_allowed') is True:
        raise ActionNotCertificationError("External mutations not allowed in certification mode.")
    
    # Check production adoption not allowed
    if contract.get('production_adoption_allowed') is True:
        raise ActionNotCertificationError("Production adoption not allowed in certification mode.")
    
    # Check egress mode is dry_run
    if contract.get('egress_mode') != 'dry_run':
        raise ActionNotCertificationError(f"Egress mode must be dry_run, got: {contract.get('egress_mode')}")
    
    # Check verdict space is valid
    valid_verdicts = ['CERTIFIED', 'QUALIFIED_PARTIAL', 'NOT_CERTIFIED', 'BLOCKED']
    verdict_space = contract.get('verdict_space', [])
    for v in verdict_space:
        if v not in valid_verdicts:
            raise CertificationContractError(f"Invalid verdict in verdict_space: {v}")
    
    # Check contract has contract_hash (or null for pre-freeze)
    if 'contract_hash' not in contract:
        raise CertificationContractError("Contract missing contract_hash field.")

def verify_no_production_mutation(trace: list) -> bool:
    """Verify trace contains no production mutations."""
    for event in trace:
        payload = event.get('payload', {})
        if payload.get('production_mutation') is True:
            return False
        if payload.get('mode') == 'production':
            return False
    return True

def verify_dry_run_egress(trace: list) -> bool:
    """Verify egress events are dry-run only."""
    for event in trace:
        if event.get('phase') == 'c11_egress':
            payload = event.get('payload', {})
            if payload.get('mode') != 'dry_run':
                return False
            if payload.get('governance_gate') != 'allow':
                return False
    return True

def verify_no_hardcoded_paths(trace: list, forbidden_patterns: list) -> bool:
    """Verify no hardcoded paths in trace."""
    trace_str = str(trace)
    for pattern in forbidden_patterns:
        if pattern in trace_str:
            return False
    return True